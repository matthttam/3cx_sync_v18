Using module .\Modules\Config.psm1
Using module .\Modules\Mapping.psm1
Using module .\Modules\3CX\APIConnection.psm1
Using module .\Modules\3CX\Entity\ExtensionFactory.psm1
Using module .\Modules\3CX\Entity\GroupFactory.psm1

[CmdletBinding(SupportsShouldProcess)]
Param(
    [Switch] $NoExtensions,
    [Switch] $NoGroupMemberships
)

# Set security protocols that are supported
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# Check Required Modules
if (-not (Get-Module -ListAvailable -Name PSFramework)) {
	Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module PSFramework -Scope CurrentUser -Force -Confirm:$false
} 

# Change directory
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
Set-Location $dir

# Setup Logging
$logFile = Join-Path -path $dir -ChildPath 'log' | Join-Path -ChildPath "log-$(Get-date -f 'yyyyMMdd').txt";
Set-PSFLoggingProvider -Name logfile -FilePath $logFile -Enabled $true;
Write-PSFMessage -Level Output -Message 'Sync Started'

## Import Config config.json
try
{
    $ConfigPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'config.json')
    $config = [Config]::new($ConfigPath)
    $config.verify(@('BaseUrl','Password','Username'))
}
catch [System.IO.FileNotFoundException]
{
    $response = Read-Host 'Run Setup script now? [Yn]'
    if($response -eq '' -or $response.ToLower() -eq 'y'){
        & "$dir\Setup.ps1"
    }else{
        Write-Error 'Exitting. config is required to run this sync.' -ErrorAction Stop
    }
}
catch
{
    Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
}

## Import Config\Mapping.json
try
{
    $MappingPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'Mapping.json')
    $MappingConfig = [Config]::new($MappingPath);
}
catch
{
    Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
}

$3CXApiConnection = [APIConnection]::New($config)
try{
    $3CXApiConnection.login()
}catch{
    Write-Error 'Failed to connect to the 3CX Api with the provided config information.' -ErrorAction Stop
}


if(-NOT $NoExtensions){

    # Extract New and Update extension mappings
    $NewMapping = [Mapping]::New($MappingConfig.Config.Extension.New)
    $UpdateMapping = [Mapping]::New($MappingConfig.Config.Extension.Update)
    ## Import Extension CSV File
    try
    {
        $ExtensionImportCSV = [Config]::New($MappingCOnfig.Config.Extension.Path, [Config]::CSV)
        #Verify ImportData isn't Empty
        if(-not $ExtensionImportCSV.Config.Count -gt 0){
            Write-Error 'Import File is Empty' -ErrorAction Stop
        }
    }
    catch
    {
        Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
    }

    # Get A List of Extensions
    $Response = $3CXApiConnection.Endpoints.ExtensionList.Get()
    $ExtensionList = $Response.Content | ConvertFrom-Json | Select-Object -ExpandProperty 'list'
    $ExtensionFactory = [ExtensionFactory]::new($3CXApiConnection.Endpoints.ExtensionList)
    $Extensions = $ExtensionFactory.makeExtension($ExtensionList)
    $ExtensionNumbers = $Extensions | Select-Object -ExpandProperty id
    $CSVNumberHeader = $NewMapping.Config.Number
    $UpdateMappingCSVKeys = $UpdateMapping.GetConfigCSVKeys()
    $NewMappingCSVKeys = $NewMapping.GetConfigCSVKeys()

    # Loop over CSV
    foreach ($row in $ExtensionImportCSV.Config) {
        # If the row's CSVNumberHeader does exist in the extentions list, Update
        if($row.$CSVNumberHeader -in $ExtensionNumbers){
            $CurrentExtension = $ExtensionFactory.makeExtension($row.$CSVNumberHeader)

            $UpdateRequired = $false
            foreach($CSVHeader in $UpdateMappingCSVKeys)
            {
                $CurrentExtensionValueAttributeInfo = $CurrentExtension.GetObjectAttributeInfo($UpdateMapping.GetParsedConfigValues($CSVHeader))
                $CurrentExtensionValue = $CurrentExtension.GetObjectValue($CurrentExtensionValueAttributeInfo)
                $CSVValue = $UpdateMapping.ConvertToType( $row.$CSVHeader, $CurrentExtensionValueAttributeInfo )
                if( $CurrentExtensionValue -ne $CSVValue)
                {
                    $UpdateRequired = $true
                    $payload = $CurrentExtension.GetUpdatePayload($UpdateMapping.GetParsedConfig($CSVHeader), $CSVValue)
                    $message = ("Staged update to extension '{0}' for field '{1}'. Old Value: '{2}' NewValue: '{3}'" -f ($row.$CSVNumberHeader, $CSVHeader, $CurrentExtensionValue, $CSVValue))
                    if ($PSCmdlet.ShouldProcess($row.$CSVNumberHeader, $message))
                    {
                        $UpdateResponse = $3CXApiConnection.Endpoints.ExtensionList.Update($payload)
                        Write-PSFMessage -Level Output -Message ($message)
                    }
                }

            }
            if($UpdateRequired){
                try {

                    $message = ("Updated Extension: '{0}'" -f $row.$CSVNumberHeader)
                    if ($PSCmdlet.ShouldProcess($row.$CSVNumberHeader, $message))
                    {
                        $response = $3CXApiConnection.Endpoints.ExtensionList.Save($CurrentExtension)
                        Write-PSFMessage -Level Output -Message ($message)
                    }
                    
                }
                catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Update Extension: '{0}'" -f $row.$CSVNumberHeader)
                }
            }
        
        # If the row's CSVNumberHeader doesn't exist in the extentions list, Create
        }else{
            Write-Verbose ("Need to Create Extension: '{0}'" -f $row.$CSVNumberHeader)
            # Begin building new extension
            $NewExtensionResult = $3CXApiConnection.Endpoints.ExtensionList.New()
            $NewExtensionObject = $NewExtensionResult.Content | ConvertFrom-Json -ErrorAction Stop
            $NewExtension = $ExtensionFactory.makeExtension($NewExtensionObject)

            foreach( $CSVHeader in $NewMappingCSVKeys)
            {
                try {
                    $NewExtensionValueAttributeInfo = $CurrentExtension.GetObjectAttributeInfo($NewMapping.GetParsedConfigValues($CSVHeader))
                    $CSVValue = $NewMapping.ConvertToType( $row.$CSVHeader, $NewExtensionValueAttributeInfo )
                    $payload = $NewExtension.GetUpdatePayload( $NewMapping.GetParsedConfig($CSVHeader) , $CSVValue)

                    $message = ("Staged update to new extension '{0}' for field '{1}'. Value: '{3}'" -f ($row.$CSVNumberHeader, $CSVHeader, $CSVValue))
                    if ($PSCmdlet.ShouldProcess($row.$CSVNumberHeader, $message))
                    {
                        $UpdateResponse = $3CXApiConnection.Endpoints.ExtensionList.Update($payload)
                        Write-PSFMessage -Level Output -Message ($message)
                    }
                    
                } catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Create Extension '{0}' due to a staging error on update parameters." -f ($row.$CSVNumberHeader))
                    continue
                }
            }
            try {
                $message = ("Created Extension: '{0}'" -f $row.$CSVNumberHeader)
                if ($PSCmdlet.ShouldProcess($row.$CSVNumberHeader, $message))
                {
                    $response = $3CXApiConnection.Endpoints.ExtensionList.Save($NewExtension)    
                    Write-PSFMessage -Level Output -Message ($message)
                }
            }
            catch {
                Write-PSFMessage -Level Critical -Message ("Failed to Create Extension: '{0}'" -f $row.$CSVNumberHeader)
            }
            
            
        }

    }
}

if(-NOT $NoGroupMemberships){
    ## Import GroupMembership CSV File
    try
    {
        $GroupMembershipImportCSV = [Config]::New($MappingCOnfig.Config.GroupMembership.Path, [Config]::CSV)
        #Verify ImportData isn't Empty
        if(-not $GroupMembershipImportCSV.Config.Count -gt 0){
            Write-Error 'Import File is Empty' -ErrorAction Stop
        }
    }
    catch
    {
        Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
    }
    # Parse GroupMapping.json file
    # Get A List of Extensions
    #$Response = $3CXApiConnection.Endpoints.ExtensionList.Get()
    
    # Get Groups
    #$Response = $3CXApiConnection.Endpoints.GroupList.Get();
    
    #Loop: Groups
    foreach($Group in $Groups){
        # If Group in Config #$MappingCOnfig.Config.GroupMembership.Groups
            #$GroupMemberships - GetLiveGroupMemberships
            # Loop over CSV Data
            foreach($row in $GroupMembershipImportCSV.Config){
                
                # Use Condition logic on row
                # If TRUE
                # REMOVE from array
                    #If IN $GroupMemberships
                    #ELSE
                    # Add to GroupMemberships
            }
            # Remove leftovers in array from groups
    }
}
Write-PSFMessage -Level Output -Message 'Sync Ended'
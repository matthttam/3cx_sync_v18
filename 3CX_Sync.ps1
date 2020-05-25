Using module .\Modules\Config.psm1
Using module .\Modules\ExtensionMapping.psm1
Using module .\Modules\GroupMembershipMapping.psm1
Using module .\Modules\3CX\APIConnection.psm1
Using module .\Modules\3CX\Entity\ExtensionFactory.psm1
Using module .\Modules\3CX\Entity\GroupFactory.psm1

[CmdletBinding(SupportsShouldProcess)]
Param(
    [Switch] $NoExtensions,
    [Switch] $NoGroupMemberships,
    [Switch] $NoNewExtensions,
    [Switch] $NoUpdateExtensions
)

# Set security protocols that are supported
[Net.ServicePointManager]::SecurityProtocol = "tls12"

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
    $NewMapping = [ExtensionMapping]::New($MappingConfig.Config.Extension.New)
    $UpdateMapping = [ExtensionMapping]::New($MappingConfig.Config.Extension.Update)
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
    try{
        $ExtensionList = $3CXApiConnection.Endpoints.ExtensionListEndpoint.Get() | Select-Object -ExpandProperty 'list'
    }catch {
        Write-Error ('Failed to Look Up Extension List due to an unexpected error. ' + $PSItem.Exception.Message) -ErrorAction Stop
    }
    
    $ExtensionFactory = [ExtensionFactory]::new($3CXApiConnection.Endpoints.ExtensionListEndpoint)
    $Extensions = $ExtensionFactory.makeExtension($ExtensionList)
    $ExtensionNumbers = $Extensions | Select-Object -ExpandProperty id
    $CSVNumberHeader = $NewMapping.Config.Number
    $UpdateMappingCSVKeys = $UpdateMapping.GetConfigCSVKeys()
    $NewMappingCSVKeys = $NewMapping.GetConfigCSVKeys()

    # Loop over CSV
    foreach ($row in $ExtensionImportCSV.Config) {
        # If the row's CSVNumberHeader does exist in the extentions list, Update
        if($row.$CSVNumberHeader -in $ExtensionNumbers){
            if($NoUpdateExtensions -eq $false){
                try{
                    $CurrentExtension = $ExtensionFactory.makeExtension($row.$CSVNumberHeader)
                }catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Look Up Extension '{0}' due to an unexpected error. {1}" -f ($row.$CSVNumberHeader, $PSItem.Exception.Message))
                    continue
                }
                

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
                        try{
                            if ($PSCmdlet.ShouldProcess($row.$CSVNumberHeader, $message))
                            {
                                $UpdateResponse = $3CXApiConnection.Endpoints.ExtensionListEndpoint.Update($payload)
                                Write-PSFMessage -Level Output -Message ($message)
                            }
                        }catch{
                            Write-PSFMessage -Level Critical -Message ("Failed to Stage Update to Extension '{0}' for CSV Header {1} due to a staging error on update parameters." -f ($row.$CSVNumberHeader, $CSVHeader))
                            continue
                        }
                    }
                }
                if($UpdateRequired){
                    try {

                        $message = ("Updated Extension: '{0}'" -f $row.$CSVNumberHeader)
                        if ($PSCmdlet.ShouldProcess($row.$CSVNumberHeader, $message))
                        {
                            $response = $3CXApiConnection.Endpoints.ExtensionListEndpoint.Save($CurrentExtension)
                            Write-PSFMessage -Level Output -Message ($message)
                        }
                        
                    }
                    catch {
                        Write-PSFMessage -Level Critical -Message ("Failed to Update Extension: '{0}'" -f $row.$CSVNumberHeader)
                    }
                }
            }
        # If the row's CSVNumberHeader doesn't exist in the extentions list, Create
        }else{
            if($NoNewExtensions -eq $false){
                Write-Verbose ("Need to Create Extension: '{0}'" -f $row.$CSVNumberHeader)
                # Begin building new extension
                try {
                    $NewExtension = $ExtensionFactory.makeExtension()
                }catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Stage Creation of New Extension '{0}' due to an unexpected error." -f ($row.$CSVNumberHeader))
                    continue
                }

                foreach( $CSVHeader in $NewMappingCSVKeys)
                {
                    $NewExtensionValueAttributeInfo = $CurrentExtension.GetObjectAttributeInfo($NewMapping.GetParsedConfigValues($CSVHeader))
                    $CSVValue = $NewMapping.ConvertToType( $row.$CSVHeader, $NewExtensionValueAttributeInfo )
                    $payload = $NewExtension.GetUpdatePayload( $NewMapping.GetParsedConfig($CSVHeader) , $CSVValue)

                    $message = ("Staged update to new extension '{0}' for field '{1}'. Value: '{2}'" -f ($row.$CSVNumberHeader, $CSVHeader, $CSVValue))
                    try {
                        if ($PSCmdlet.ShouldProcess($row.$CSVNumberHeader, $message))
                        {
                            $UpdateResponse = $3CXApiConnection.Endpoints.ExtensionListEndpoint.Update($payload)
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
                        $response = $3CXApiConnection.Endpoints.ExtensionListEndpoint.Save($NewExtension)    
                        Write-PSFMessage -Level Output -Message ($message)
                    }
                }
                catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Create Extension: '{0}'" -f $row.$CSVNumberHeader)
                }
                
                
            }
        }
    }
}

if(-NOT $NoGroupMemberships){
    ## Import GroupMembership CSV File
    try
    {
        $GroupMembershipImportCSV = [Config]::New($MappingConfig.Config.GroupMembership.Path, [Config]::CSV)
        #Verify ImportData isn't Empty
        if(-not $GroupMembershipImportCSV.Config.Count -gt 0){
            Write-Error 'Import File is Empty' -ErrorAction Stop
        }
    }
    catch
    {
        Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
    }

    # Get GroupMembershipMapping
    $GroupMembershipMapping = [GroupMembershipMapping]::New($MappingConfig.Config.GroupMembership.Groups)
        
    # Get Groups
    $GroupList = $3CXApiConnection.Endpoints.GroupListEndpoint.Get() | Select-Object -ExpandProperty 'list'
    $GroupFactory = [GroupFactory]::new($3CXApiConnection.Endpoints.GroupListEndpoint)
    $Groups = $GroupFactory.makeGroup($GroupList)
    foreach($Group in $Groups){
        $GroupMembershipMappingNames = $GroupMembershipMapping.GetConfigPathKeys()
        if($Group.object.Name -in $GroupMembershipMappingNames){
            try{
                $CurrentGroup = $GroupFactory.makeGroup($Group.object.Id)
            }catch{
                Write-PSFMessage -Level Critical -Message ("Failed to Look Up Group '{0}' due to an unexpected error." -f ($Group.object.Name))
                continue
            }
            
            [System.Collections.ArrayList] $SelectedExtensions = @() # Used to log what was added

            # Loop over CSV Data
            foreach($row in $GroupMembershipImportCSV.Config){
                # Determine Proper Extensions in Group
                if($GroupMembershipMapping.EvaluateConditions( $GroupMembershipMapping.config.($Group.object.Name).Conditions, $row) ){
                    # IF Not Found in Possible Extensions, Continue
                    $FoundValue = $CurrentGroup.GetPossibleValueByNumber($row.Number)
                    if(-not $FoundValue){
                        Write-PSFMessage -Level Warning -Message ('Extension Number {0} not valid for group {1}' -f $row.Number, $CurrentGroup.object.Name._value)
                        Continue
                    }else{
                        if(-not ($SelectedExtensions -contains $FoundValue)){
                            $SelectedExtensions += $FoundValue
                        }
                    }
                }
            }

            $Comparison = Compare-Object -ReferenceObject ($CurrentGroup.GetSelected()) -DifferenceObject ($SelectedExtensions | Select-Object -ExpandProperty Id)
            if($Comparison.length -ne 0){
                
                $ExtensionIdsToAdd = $Comparison | Where-Object -Property SideIndicator -Eq '=>' | Select-Object -ExpandProperty InputObject
                $ExtensionIdsToRemove = $Comparison | Where-Object -Property SideIndicator -Eq '<=' | Select-Object -ExpandProperty InputObject
                $MessageInfoTemplate = @{label="Info";expression={$_.Number._value + ' - ' + $_.FirstName._value + ' ' + $_.LastName._value}}

                if($ExtensionIdsToAdd.count -gt 0)
                {
                    $ExtensionToAddInfo = $SelectedExtensions | Where-Object -FilterScript {$_.Id -in $ExtensionIdsToAdd} | Select-Object -Property $MessageInfoTemplate | Select-Object -ExpandProperty Info
                    $message = ("Staged Update to Group '{0}' to Add Extension(s) '{1}'" -f $Group.object.Name, ($ExtensionToAddInfo -join "', '"))
                    try{
                        if ($PSCmdlet.ShouldProcess($Group.object.Name, $message))
                        {
                            $payload = $CurrentGroup.GetUpdatePayload(@(@{"Name" = "Members"}), $ExtensionIdsToAdd)
                            $UpdateResponse = $3CXApiConnection.Endpoints.ExtensionListEndpoint.Update($payload)
                            Write-PSFMessage -Level Output -Message ($message)
                        }
                    }catch{
                        Write-PSFMessage -Level Critical -Message ("Failed to Update Group '{0}' due to a staging error." -f ($Group.object.Name))
                        continue;
                    }

                    try{
                        $AddMessage = ("Updated Group: '{0}'. Added extension(s): '{1}'" -f $Group.object.Name, ($ExtensionToAddInfo -join "', '") )
                        if ($PSCmdlet.ShouldProcess($Group.object.Name, $AddMessage))
                        {
                            $response = $3CXApiConnection.Endpoints.GroupListEndpoint.Save($CurrentGroup)    
                            Write-PSFMessage -Level Output -Message ($AddMessage)
                        }
                    }catch{
                        Write-PSFMessage -Level Critical -Message ("Failed to Update Group: '{0}'" -f $Group.object.Name )
                    }
                }

                if($ExtensionIdsToRemove.count -gt 0){
                    $ExtensionToRemoveInfo = $CurrentGroup.Object.Members.possibleValues | Where-Object -FilterScript {$_.Id -in $ExtensionIdsToRemove} | Select-Object -Property $MessageInfoTemplate | Select-Object -ExpandProperty Info
                    $RemovedMessage = ("Updated Group: '{0}'. Removed extension(s): '{1}'" -f $Group.object.Name, ($ExtensionToRemoveInfo -join "', '") )
                    if($PSCmdlet.ShouldProcess($Group.object.Name, $RemovedMessage)){
                        Write-PSFMessage -Level Output -Message ($RemovedMessage)
                    }
                }
            }
        }
    }
}
Write-PSFMessage -Level Output -Message 'Sync Ended'
Using module .\Modules\Config.psm1
Using module .\Modules\Mapping.psm1
Using module .\Modules\3CX\APIConnection.psm1
Using module .\Modules\3CX\Entity\ExtensionFactory.psm1

# Check Required Modules
if (-not (Get-Module -ListAvailable -Name PSFramework)) {
    Install-Module PSFramework -Force -Confirm:$false
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
    $config = [Config]::New($ConfigPath)
    $config.verify(@('BaseUrl','Password','Username','ImportFilename'))
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

## Import Config NewMapping.json
try
{
    $NewMappingPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'NewMapping.json')
    $NewMapping = [Mapping]::New($NewMappingPath)
    $NewMapping.verify(@('Number'))
}
catch
{
    Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
}

## Import Config UpdateMapping.json
try
{
    $UpdateMappingPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'UpdateMapping.json')
    $UpdateMapping = [Mapping]::New($UpdateMappingPath)
}
catch
{
    Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
}

## Import CSV File
try
{
    $ImportFilePath = (Join-Path -Path $dir -ChildPath 'Import Files' | Join-Path -ChildPath $config.Config.ImportFilename)
    $ExtensionImportCSV = [Config]::New($ImportFilePath, [Config]::CSV)
}
catch
{
    Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
}

## Verify Config Files
#Verify ImportData isn't Empty
if(-not $ExtensionImportCSV.Config.Count -gt 0){
    Write-Error 'Import File is Empty' -ErrorAction Stop
}

$3CXApiConnection = [APIConnection]::New($config)
try{
    $3CXApiConnection.login()
}catch{
    Write-Error 'Failed to connect to the 3CX Api with the provided config information.' -ErrorAction Stop
}

# Get A List of Extensions
$Response = $3CXApiConnection.Endpoints.ExtensionList.Get()
$ExtensionList = $Response.Content | ConvertFrom-Json | Select-Object -ExpandProperty 'list'
#$ExtensionListNumber = $ExtensionList | Select-Object -ExpandProperty Number
$ExtensionFactory = [ExtensionFactory]::new($3CXApiConnection.Endpoints.ExtensionList)
$Extensions = $ExtensionFactory.makeExtension($ExtensionList)
#$ExtensionNumbers =  $Extensions | Select-Object -property object | Select-object -ExpandProperty object | Select-Object -ExpandProperty Number
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
                $UpdateResponse = $3CXApiConnection.Endpoints.ExtensionList.Update($payload)
                Write-PSFMessage -Level Output -Message ('Staged update to extension "{0}" for field "{1}". Old Value: "{2}" NewValue: "{3}"' -f ($row.$CSVNumberHeader, $CSVHeader, $CurrentExtensionValue, $CSVValue))
            }

        }
        if($UpdateRequired){
            try {
                $response = $3CXApiConnection.Endpoints.ExtensionList.Save($CurrentExtension)
                Write-PSFMessage -Level Output -Message ('Updated Extension: "{0}"' -f $row.$CSVNumberHeader)
            }
            catch {
                Write-PSFMessage -Level Critical -Message ('Failed to Update Extension: "{0}"' -f $row.$CSVNumberHeader)
            }
        }
    
    # If the row's CSVNumberHeader doesn't exist in the extentions list, Create
    }else{
        Write-Verbose ('Need to Create Extension: "{0}"' -f $row.$CSVNumberHeader)
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
            $UpdateResponse = $3CXApiConnection.Endpoints.ExtensionList.Update($payload)
            } catch {
                Write-PSFMessage -Level Critical -Message ('Failed to Create Extension "{0}" due to a staging error on update parameters.' -f ($row.$CSVNumberHeader))
                continue
            }
        }
        try {
            $response = $3CXApiConnection.Endpoints.ExtensionList.Save($NewExtension)    
            Write-PSFMessage -Level Output -Message ('Created Extension: "{0}"' -f $row.$CSVNumberHeader)
        }
        catch {
            Write-PSFMessage -Level Critical -Message ('Failed to Create Extension: "{0}"' -f $row.$CSVNumberHeader)
        }
        
        
    }

}
Write-PSFMessage -Level Output -Message 'Sync Ended'
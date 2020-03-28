Using module .\Modules\Config.psm1
Using module .\Modules\Mapping.psm1
Using module .\Modules\3CX\APIConnection.psm1

# Change directory
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
Set-Location $dir

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
#$3CXApiConnection.Endpoints.ExtensionList.New()
#exit
#$Response = $3CXApiConnection.get('ExtensionList')
$Response = $3CXApiConnection.Endpoints.ExtensionList.Get()
$ExtensionList = $Response.Content | ConvertFrom-Json | Select-Object -ExpandProperty 'list'
$ExtensionListNumber = $ExtensionList | Select-Object -ExpandProperty Number

# Loop over CSV
foreach ($row in $ExtensionImportCSV.Config) {
    $CSVNumberHeader = $NewMapping.Config.Number
    #If it exists, skip
    if($row.$CSVNumberHeader -in $ExtensionListNumber){
        continue;
        # Todo - Determine if certain fields are different and if they are queue for update
    }else{
        Write-Verbose ('Need to Create {0}' -f $row.Number)
        # Begin building new extension
        $NewExtensionResult = $3CXApiConnection.Endpoints.ExtensionList.New()
        $NewExtension = $NewExtensionResult.Content | ConvertFrom-Json -ErrorAction Stop
        
        $keys = $row.PSObject.Properties | Select-Object -ExpandProperty 'Name'
        foreach( $CSVHeader in $keys){
            $payload = $NewMapping.GetUpdatePayload( $NewExtension, [string] $CSVHeader, $row.$CSVHeader)
            $UpdateResponse = $3CXApiConnection.Endpoints.ExtensionList.Update($payload)
        }
        $response = $3CXApiConnection.Endpoints.ExtensionList.Save($NewExtension)
        
    }

# If it doesn't exist, Create
}
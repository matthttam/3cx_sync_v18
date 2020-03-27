Using module .\Modules\Config.psm1
Using module .\Modules\Mapping.psm1
Using module .\Modules\APIConnection.psm1

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
    Write-Error 'Unexpected Error' -ErrorAction Stop
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
    Write-Error 'Unexpected Error' -ErrorAction Stop
}

## Import CSV File
try
{
    $ImportFilePath = (Join-Path -Path $dir -ChildPath 'Import Files' | Join-Path -ChildPath $config.Config.ImportFilename)
    $ExtensionImportCSV = [Config]::New($ImportFilePath, [Config]::CSV)
}
catch
{
    Write-Error 'Unexpected Error' -ErrorAction Stop
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
$Response = $3CXApiConnection.get('ExtensionList')
$ExtensionList = $Response.Content | ConvertFrom-Json | Select-Object -ExpandProperty 'list'

$ExtensionListNumber = $ExtensionList | Select-Object -ExpandProperty Number

function New-3CXExtension([ApiConnection] $Connection)
{
    return $Connection.get('ExtensionList/new')
}

function Update-3CXExtension()
<#

function BuildExtensionUpdateParameters(){
    params(
        $ObjectID,
        $Mapping,
        $Data
    )
    $CSVHeaders = $Mapping.PSObject.Properties | Select-Object -ExpandProperty 'Name'
    $3CXPaths = $NewMapping.PSObject.Properties | Select-Object -ExpandProperty 'Value'
    foreach($
    $return = @{
        #Path = @{
        #    
        #},
        #PropertyValue = '00001ab'
    }

    #{"Path":{"ObjectId":"40","PropertyPath":[{"Name":"Number"}]},"PropertyValue":"00001ab"}


    return @{}
}
#>
# Loop over CSV
foreach ($row in $ImportData) {
    #If it exists, skip
    if($row.$CSVExtensionNumberField -in $ExtensionListNumber){
        continue;
        # Todo - Determine if certain fields are different and if they are queue for update
    }else{
        #$Queue_ExtensionNew += $row
        Write-Verbose ('Need to Create {0}' -f $row.Number)
    }

# If it doesn't exist, Create
}
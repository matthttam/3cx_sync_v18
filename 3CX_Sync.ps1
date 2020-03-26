# FUNCTIONS
function GetValue($object, $key)
{
    $p1,$p2 = $key.Split(".")
    if($p2) { return GetValue -object $object.$p1 -key $p2 }
    else { return $object.$p1 }
}

function SetValue($object, $key, $Value)
{
    $p1,$p2 = $key.Split(".")
    if($p2) { SetValue -object $object.$p1 -key $p2 -Value $Value }
    else { $object.$p1 = $Value }
}

function Test-ConfigPath($path)
{
    $filename = $path | Split-Path -Leaf
    if(-not (Test-Path -Path $path )){
        Write-Warning ('{0} not located in {1}.' -f $filename, $path )
        return $false
    }
    return $true
}

class Config
{
    [string]$FullPath
    [string]$Path
    [string]$Filename
    [PSCustomObject]$Config

    Config([string]$FullPath)
    {
        $this.Path = Split-Path $FullPath
        $this.Filename = Split-Path $FullPath -Leaf

        # Verify File Exists
        if(-not (Test-ConfigPath -path $FullPath))
        {
            throw [System.IO.FileNotFoundException]::new("Could not find file: $FullPath", $FullPath)
        }else{
            Write-Verbose ('{0} found' -f $FullPath)
        }

        # Read the File
        $this.Config = (Get-Content -Path $FullPath) | ConvertFrom-Json -ErrorAction Stop
    }

    [void] verify([array]$RequiredProperties)
    {
        $ConfigProperties = Get-Member -InputObject $this.config -MemberType Properties | Select-Object -ExpandProperty "Name"
        $ComparisonDifference = Compare-Object -ReferenceObject $ConfigProperties -DifferenceObject $RequiredProperties
        $MissingProperties = $ComparisonDifference | Where-Object sideIndicator -eq '=>' | Select-Object -ExpandProperty 'InputObject'
        if($MissingProperties){
            Write-Error ('Fatal Error! Config file "{0}" located in {1} missing required settings: {2}' -f ($this.Filename, $this.Path, ($MissingProperties -join ', '))) -ErrorAction Stop
        }else{
            Write-Verbose('Validation of {0} successful' -f $this.Filename)
        }
    }
}

class Mapping : Config
{
    Mapping([string]$a) : base($a)
    {
        $this.Config = $this.ParseConfig($this.Config)
    }

    [PSCustomObject] ParseConfig([PSCustomObject] $config)
    {
        # NOT DONE YET
        Get-Member -InputObject $this.config -MemberType Properties | Select-Object -ExpandProperty "Name"
        return $config
    }
    
}

class APIConnection
{
    [string]$BaseUrl
    [string] hidden $Credentials
    [hashtable] $ConnectionSettings
    [System.Object] $Session

    APIConnection( [Config]$config )
    {
        $this.BaseUrl = $config.Config.BaseUrl.Trim('/')
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( ($config.Config.Password | ConvertTo-SecureString))
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
        $this.Credentials = ((@{
            Username = $config.Config.Username
            Password = $PlainPassword
        }) | ConvertTo-Json)
    }

    Login()
    {
        $LoginResponse = Invoke-WebRequest -Uri ('{0}/login' -f $this.BaseUrl) -Method Post -ContentType "application/json;charset=UTF-8" -Body $this.Credentials.ToString() -SessionVariable 'Session'
        $this.Session = Get-Variable -name Session -ValueOnly
        if( $LoginResponse.Content -ne 'AuthSuccess' ){
            Write-Error 'Failed to authenticate' -ErrorAction Stop
            throw [System.Security.Authentication.InvalidCredentialException]::new("Failed to authenticate")
        }
        $Cookies = $this.Session.Cookies.GetCookies('{0}/login' -f $this.BaseUrl)
        $XSRF = ($Cookies | Where-Object  name -eq "XSRF-TOKEN").Value
        $this.ConnectionSettings = @{
            WebSession = $this.Session
            Headers = @{"x-xsrf-token"="$XSRF"}
            ContentType = "application/json;charset=UTF-8"
        }
    }

    [Microsoft.PowerShell.Commands.WebResponseObject] get([string]$Path)
    {
        $parameters = $this.ConnectionSettings
        return (Invoke-WebRequest -Uri ('{0}/{1}' -f $this.BaseUrl, $Path) -Method Get @parameters)
    }

    [Microsoft.PowerShell.Commands.WebResponseObject] post([string]$Path)
    {
        $parameters = $this.ConnectionSettings
        return Invoke-WebRequest -Uri ('{0}/{1}' -f $this.BaseUrl, $Path) -Method Post @parameters
    }

}

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
    #$blah = $NewMapping.test()
}
catch
{
    Write-Error 'Unexpected Error' -ErrorAction Stop
}



# Verify NewMapping Exists
<#
$NewMappingPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'NewMapping.json')
if(-not (Test-ConfigPath -path $NewMappingPath))
{
    Write-Error 'Exitting. NewMapping is required to run this sync.' -ErrorAction Stop
}else{
    Write-Verbose 'NewMappingPath.json found'
}
#>

# Read NewMapping File
<#
try{
    $NewMapping = (Get-Content -Path $NewMappingPath) | ConvertFrom-Json -ErrorAction Stop # Read Config and convert to json object
}catch{
    Write-Error -Message 'Fatal Error! Unable to read NewMapping.json' -ErrorAction Stop
}
#>

## Verify CSV Files exit
$ImportFilePath = (Join-Path -Path $dir -ChildPath 'Import Files' | Join-Path -ChildPath $config.Config.ImportFilename)
if(-not (Test-ConfigPath -path $ImportFilePath))
{
    Write-Error 'Exitting. Import file specified in config not found.' -ErrorAction Stop
}else{
    Write-Verbose  ('{0} found' -f $config.ImportFilename)
}

# Read in CSV File
try{
    $ImportData = (Get-Content -Path $ImportFilePath) | ConvertFrom-Csv -ErrorAction Stop # Read Config and convert to json object
}catch{
    Write-Error -Message ('Fatal Error! Unable to read {0}' -f $config.ImportFilename) -ErrorAction Stop
}

## Verify Config Files
#Verify ImportData isn't Empty
if(-not $ImportData.Count -gt 0){
    Write-Error 'Import File is Empty'
    exit
}

# Verify NewMapping has required fields
#$CSVExtensionNumberField = $NewMapping.Config.PSObject.Properties | Where-Object {$_.Value -eq 'Number'} | Select-Object -ExpandProperty 'Name'
#if(-not $CSVExtensionNumberField){
#    Write-Error ('Fatal Error! NewMapping missing required field Number')
#    exit
#}
#[string]$BaseUrl, [string]$Username, [string] $Password
#$3CXApiConnection = [APIConnection]::New($config.BaseUrl, $config.Username, $config.Password)
$3CXApiConnection = [APIConnection]::New($config)
try{
    $3CXApiConnection.login()
}catch{
    Write-Error 'Failed to connect to the 3CX Api with the provided config information.'
    exit
}



#$test5 = Invoke-WebRequest -Uri "https://owensboro.my3cx.us:5001/api/ExtensionList/set" -WebSession $Session -Method "POST" -Headers @{"x-xsrf-token"="$XSRF"} -ContentType "application/json;charset=UTF-8" -Body "{`"Id`":`"00000`"}"
#$test5.Content

# Get A List of Extensions
$Response = $3CXApiConnection.get('ExtensionList')
$ExtensionList = $Response.Content | ConvertFrom-Json | Select-Object -ExpandProperty 'list'

$ExtensionListNumber = $ExtensionList | Select-Object -ExpandProperty Number
$Queue_ExtensionNew = @();
$Queue_ExtensionUpdate = [System.Collections.ArrayList] @();
Write-Host $ExtensionList.count 

exit

<#
function ParseMapping(){
    #params(
        #$Mapping
#}
    $return = $NewMapping.PSObject.Properties | Select-Object -ExpandProperty 'Value'
}

function New-3CXExtension()
{
    return 
}

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
        $Queue_ExtensionNew += $row
        Write-Verbose ('Need to Create {0}' -f $row.Number)
    }

# If it doesn't exist, Create
}
$Queue_ExtensionNew
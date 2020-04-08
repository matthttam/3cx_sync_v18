param(
	[switch] $Update
)
function Write-Config(){
    param(
        [string] $ConfigPath,
        [PSCustomObject] $Config
    )
    $config | ConvertTo-Json | Out-File -FilePath $ConfigPath -Confirm:$false
}

function Prompt-User(){
    param(
        [string] $Message,
        $CurrentValue = "",
        [switch] $Secure = $false
    )

    if($CurrentValue){
        $Message += ' [{0}]' -f $CurrentValue
    }
    return Read-Host $Message -AsSecureString:$Secure
}

# Change directory
 $scriptpath = $MyInvocation.MyCommand.Path
 $dir = Split-Path $scriptpath
 Set-Location $dir

$ConfigPath = Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'config.json'
$ConfigExists = (Test-Path -Path $ConfigPath)
# If config file exists prompt if we should overwrite or quit
if( $ConfigExists -and -not $Update){
    $overwrite = Read-Host 'Config File Exists. Overwrite? [Yn]'
    if( -not ($overwrite -eq '' -or $overwrite.ToLower() -eq 'y') ){
        Write-Host 'Quitting'
        exit
    }
}

if($ConfigExists -and $Update){
    try{
	    $CurrentConfig = Get-Content $ConfigPath | ConvertFrom-Json
        
    }catch{
        Write-Error "Failed to read existing config file. Please run without the update flag to overwrite or create new." -ErrorAction Stop
    }
}

if($Update){
    Write-Host "Leave responses blank to keep the current value!"
}
# Prompt for Configuration Information
$username = Prompt-User -Message 'Enter the 3CX Admin Username' -CurrentValue $CurrentConfig.Username
$password = Prompt-User 'Enter the 3CX Admin Password' -Secure
$url = Prompt-User 'Enter the 3CX api URL (e.g. https://site.my3cx.us:5001/api)' -CurrentValue $CurrentConfig.BaseUrl
$importFilename = Prompt-User 'Enter the import filename (e.g. import.csv)' -CurrentValue $CurrentConfig.ImportFilename
# -AsSecureString

if($Update){
    $config = $CurrentConfig
}else{
    $config = @{
        Username = ""
        Password = @{}
        BaseUrl = ""
        ImportFilename = ""
    }
}

if($username){
    $config.Username = $username
}
if($password.Length -ne 0){
    #$config.Password += @{([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) = (ConvertFrom-SecureString -SecureString $password)}
    $config.Password += @{'Username' = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name; 'Password' = (ConvertFrom-SecureString -SecureString $password)}
}
if($url){
    $config.BaseUrl = $url.Trim('/')
}
if($importFilename){
    $config.ImportFilename = $importFilename
}

# Save config.json with encrypted password and other config information
Write-Config -ConfigPath $ConfigPath -Config $config
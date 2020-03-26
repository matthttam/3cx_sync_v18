# Change directory
 $scriptpath = $MyInvocation.MyCommand.Path
 $dir = Split-Path $scriptpath
 cd $dir

# If config file exists prompt if we should overwrite or quit
if((Test-Path -Path 'config.json')){
    $overwrite = Read-Host 'Config File Exists. Overwrite? [Yn]'
    if( -not ($overwrite -eq '' -or $overwrite.ToLower() -eq 'y') ){
        Write-Host 'Quitting'
        exit
    }
}

# Prompt for Configuration Information
$username = Read-Host 'Enter the 3CX Admin Username'
$password = Read-Host 'Enter the 3CX Admin Password' -AsSecureString
$url = Read-Host 'Enter the 3CX api URL (e.g. https://site.my3cx.us:5001/api)'
$importFilename = Read-Host 'Enter the import filename (e.g. import.csv)'

$config = @{
    Username = $username
    Password = ConvertFrom-SecureString -SecureString $password
    BaseUrl = $url.Trim('/')
    ImportFilename = $importFilename
}

# Save config.json with encrypted password and other config information
$config | ConvertTo-Json | Out-File -FilePath '.\Config\config.json' -Confirm:$false
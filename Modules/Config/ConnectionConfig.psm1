Using module .\Config.psm1
class ConnectionConfig : Config
{
    [Array] $RequiredFields = @('BaseUrl','Password','Username')

    ConnectionConfig($Fullpath) : base($Fullpath)
    {
        
    }

    [void] VerifyFileExists($FullPath)
    {
        $dir = Get-Location
        try
        {
            ([Config]$this).VerifyFileExists($FullPath)
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
    }
}
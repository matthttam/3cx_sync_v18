Using module ..\Config.psm1
Using module .\Endpoints\ExtensionList.psm1
class APIConnection
{
    [string]$BaseUrl
    [string] hidden $Credentials
    [hashtable] $ConnectionSettings
    [System.Object] $Session
    [hashtable] $Endpoints = @{}

    APIConnection( [Config]$config )
    {
        $this.BaseUrl = $config.Config.BaseUrl.Trim('/')
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( ($config.Config.Password | ConvertTo-SecureString))
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
        $this.Credentials = ((@{
            Username = $config.Config.Username
            Password = $PlainPassword
        }) | ConvertTo-Json)

        $this.Endpoints.ExtensionList = [ExtensionList]::New($this)
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
        return $this.post($Path, @{})
    }
    [Microsoft.PowerShell.Commands.WebResponseObject] post([string]$Path, [hashtable] $Options)
    {
        $parameters = $this.ConnectionSettings
        return Invoke-WebRequest -Uri ('{0}/{1}' -f $this.BaseUrl, $Path) -Method Post @parameters @Options
    }

}
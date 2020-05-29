Using module ..\Config.psm1
Using module .\Endpoints\ExtensionListEndpoint.psm1
Using module .\Endpoints\GroupListEndpoint.psm1

class APIConnection
{
    [string]$BaseUrl
    [string] hidden $Credentials
    [hashtable] $ConnectionSettings
    [System.Object] $Session
    [hashtable] $Endpoints = @{}

    APIConnection( [Config]$config )
    {
        $CurrentUser =  [Environment]::UserDomainNAME + '\' + [Environment]::UserName
        $this.BaseUrl = $config.Config.BaseUrl.Trim('/')
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( ( ($config.Config.Password | Where-Object -Property 'Username' -EQ $CurrentUser | Select-Object -ExpandProperty 'Password') | ConvertTo-SecureString))
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
        $this.Credentials = ((@{
            Username = $config.Config.Username
            Password = $PlainPassword
        }) | ConvertTo-Json)

        $this.Endpoints.ExtensionListEndpoint = [ExtensionListEndpoint]::New($this)
        $this.Endpoints.GroupListEndpoint = [GroupListEndpoint]::New($this)
    }

    Login()
    {
        $LoginResponse = Invoke-WebRequest -Uri ('{0}/login' -f $this.BaseUrl) -Method Post -ContentType "application/json;charset=UTF-8" -Body $this.Credentials.ToString() -SessionVariable 'Session' -UseBasicParsing
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

    [PSObject] get([string]$Path)
    {
        $parameters = $this.ConnectionSettings
        return (Invoke-WebRequest -Uri ('{0}/{1}' -f $this.BaseUrl, $Path) -Method Get @parameters -UseBasicParsing )
    }

    [PSObject] post([string]$Path)
    {
        return $this.post($Path, @{})
    }
    [PSObject] post([string]$Path, [hashtable] $Options)
    {
        $parameters = $this.ConnectionSettings
        return (Invoke-WebRequest -Uri ('{0}/{1}' -f $this.BaseUrl, $Path) -Method Post @parameters @Options -UseBasicParsing )
    }

}
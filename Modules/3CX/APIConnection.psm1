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
#Invoke-WebRequest -Uri "https://owensboro.my3cx.us:5001/api/edit/save" -Method "POST" -Headers @{"method"="POST"; "authority"="owensboro.my3cx.us:5001"; "scheme"="https"; "path"="/api/edit/save"; "accept"="application/json, text/plain, */*"; "sec-fetch-dest"="empty"; "x-xsrf-token"="CfDJ8BImnUu2n89OgDb4SU0Gs1a4zLIpe-SbSK_KP_avsFjhscsA-5zzuSrUs1GtVMRyMYr73NaLtMDO9yuiO5r5Cetqgw1wiZp_xagCIyWudIw-UJEz8KRZhx5iNYRqg2WMEjeFn0N4z_1QwXInWf9GL9GpplWG05zlxj34p7tiVnOg"; "user-agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Safari/537.36"; "origin"="https://owensboro.my3cx.us:5001"; "sec-fetch-site"="same-origin"; "sec-fetch-mode"="cors"; "referer"="https://owensboro.my3cx.us:5001/"; "accept-encoding"="gzip, deflate, br"; "accept-language"="en-US,en;q=0.9"; "cookie"=".AspNetCore.Webclient=CfDJ8BImnUu2n89OgDb4SU0Gs1aDUyZIQaMEMgl0cH8MBVq5I7pcc4R6ySWUmRl43PihD5UsNPERS99gE22R2CO0sau_sUvBPj7F1ZrpCKriFN234MiCVANUgGeKo30dLF9oXLVsSIGSicAkqx7WMKsk-w7cQNVyQKnl_rwoSZV6D24GR7OdMX1-l7ykH6fdOAdACzn6qc_RW_TDogFl_PQcG8vS-OdzdDLjMWPBP0g0RlQAE_cm3HGF9Xt-Rsvd75ZNE4dIPdw7KKvzud8Z_Yv7lSi2XMbrTPof1f2Y9iAD9z00PCX3euIqPgoGD0jx6F-1mNv9U4K-e2XHLLkFGYc8e1VNRaXeyo6KVorOs-lADH3Pu6k_F3MRz1jRpg4k2TnSqrkWD7CuSUCtDcVRF-Tbt7OZJgwZZMYNGUcuK5mzpcam7EBoSQ5xtbNvGHiOGeOYNQ; .AspNetCore.Cookies=CfDJ8BImnUu2n89OgDb4SU0Gs1aVKgmgf9tUX_kPaMBXq2EkcA6NKqNAjwVCzCGXhQKT_RHTeb0fbZY4mwq-7uCJTgRHLh-TYooGyk-H6WkzKsFAzak0_pXmA17vewhHNyJgj_mfsWuhTOO_Dad9__thItqLMbXf7kOxQiiTnv-PEmpGjIXf_vjWG28VN06MgW2bjtj_aR3Y5O3YJxb-6MfS4wiVeHsTqY-HmeHkv9xELrsAFKdsaLKPdkviVTUirT724svazOWGT-0BsW8YV_wGnfDqWOYoHagQqH4j-xHw_Ur153znGFzovLtJiSKSBAJWdofa7UBpMFd8bdHj9d9v6yu5I-0w0ARUw8Z2Sv2RtcOOa23lOaXhEQY_-XTejzdvhmNdZOBXrcEEcMGJc9917TMgo4CwW0J652tIdlSqIfet; XSRF-TOKEN=CfDJ8BImnUu2n89OgDb4SU0Gs1a4zLIpe-SbSK_KP_avsFjhscsA-5zzuSrUs1GtVMRyMYr73NaLtMDO9yuiO5r5Cetqgw1wiZp_xagCIyWudIw-UJEz8KRZhx5iNYRqg2WMEjeFn0N4z_1QwXInWf9GL9GpplWG05zlxj34p7tiVnOg; CmmSession=1591529e-f453-c38b-92e5-72de8c522631"} -ContentType "application/json;charset=UTF-8" -Body "13"
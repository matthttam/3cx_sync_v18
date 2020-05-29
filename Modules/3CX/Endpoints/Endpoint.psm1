Class Endpoint
{
    $APIConnection
    $EndpointPath

    Endpoint($APIConnection)
    {
        $this.APIConnection = $APIConnection
    }

    [PSObject] FormatResponse($response, $options)
    {
        if($options.FullResponse){
            return $response
        }else{
            return ($response.Content | ConvertFrom-Json -ErrorAction Stop)
        }
    }

    SetEndpointPath([string]$Path)
    {
        $this.EndpointPath = $Path
    }

    [string] GetEndpointPath(){
        return $this.GetEndpointPath('')
    }
    [string] GetEndpointPath([string]$append)
    {
        return (@($this.EndpointPath, $append) -join '/')
    }


    [PSObject] New() { return ($this.New(@{})) }
    [PSObject] New($options)
    {
        $response =  $this.APIConnection.post($this.GetEndpointPath('new'))
        return $this.FormatResponse( $response, $options)
    }

    [PSObject] Set($payload){ return $this.Set($payload, @{})}
    [PSObject] Set($payload, [hashtable] $options)
    {
        $response = $this.APIConnection.post( $this.GetEndpointPath('set'), @{'Body' = ($payload | ConvertTo-Json )})
        return $this.FormatResponse( $response, $options)
    }

    [PSObject] Get(){ return ($this.Get(@{})) }
    [PSObject] Get([hashtable] $options)
    {
        $response = $this.APIConnection.get($this.GetEndpointPath())
        return $this.FormatResponse( $response, $options)
    }
}
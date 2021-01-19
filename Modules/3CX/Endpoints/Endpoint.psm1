Using module ..\ValueType.psm1

Class Endpoint
{
    $APIConnection
    $EndpointPath
    $LastSetID

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


    [PSObject] New() 
    { 
        return ($this.New(@{})) 
    }
    [PSObject] New($options)
    {
        $payload = @{"Param" = @{}}
        $response =  $this.APIConnection.post($this.GetEndpointPath('new'), @{'Body' = ($payload | ConvertTo-Json )})
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

    [PSObject] Update($payload){ return ($this.Update($payload, @{})) }
    [PSObject] Update($payload, $options)
    {
        $response = $this.APIConnection.post('edit/update', @{'Body' = ($payload | ConvertTo-Json -Depth 10)} )
        return $this.FormatResponse( $response, $options)
    }

    [PSObject] ReadProperty($payload){ return ($this.ReadProperty($payload, @{})) }
    [PSObject] ReadProperty($payload, $options){
        $response = $this.APIConnection.post('edit/readProperty', @{'Body' = ($payload | ConvertTo-Json -Depth 10 )})
        return $this.FormatResponse( $response, $options)
    }

    [PSObject] Save($entity) { return ($this.Save($entity, @{})) }
    [PSObject] Save($entity, $options)
    {
        $response = $this.APIConnection.post('edit/save', @{'Body' = ($entity.Id | ConvertTo-Json )})
        $entity.SetDirty($false);
        return $this.FormatResponse( $response, $options)
    }

    [PSObject] Delete($entity) { return ($this.Delete($entity, @{})) }
    [PSObject] Delete($entity, $options){
        $response = $this.APIConnection.post('delete', @{'Body' = ($entity.Id | ConvertTo-Json )})
        $entity.SetDirty($false);
        $entity.SetDeleted($true);
        return $this.FormatResponse( $response, $options)
    }

}
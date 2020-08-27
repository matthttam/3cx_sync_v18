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


    [PSObject] New() 
    { 
        return ($this.New(@{})) 
    }
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

    [PSObject] Update($payload)
    {
        return $this.APIConnection.post('edit/update', @{'Body' = ($payload | ConvertTo-Json -Depth 10)} )
    }

    [PSObject] Save($entity)
    {
        return $this.APIConnection.post('edit/save', @{'Body' = ($entity.Id | ConvertTo-Json )})
    }

    # Functions used to convert CSV information for updates
    [hashtable] GetUpdatePayload( $PropertyPath, $CSVDataValue ){
        $payload = @{
            "Path" = @{
                "ObjectId" = $this.Id
                "PropertyPath" = $PropertyPath #$Mapping.ParsedConfig.$CSVHeader
            }
            "PropertyValue" = $CSVDataValue
        }
        return $payload
    }

    [PSObject] ConvertToType( $entity, $path, $Value )
    {
        $attributeInfo = $entity.GetObjectAttributeInfo($path)
        if($attributeInfo.Type-eq 'String'){
            return $Value
        }elseif($attributeInfo.Type -eq 'Enum'){
            if($Value -in $attributeInfo.possibleValues){
                return $Value
            }else{
                return $null #maybe throw error?
            }
            #return $attributeInfo.possibleValues[$Value]
        }elseif($attributeInfo.Type -eq 'SelectedItem'){
            return $attributeInfo.possibleValues | Where-Object Id -eq $Value
        }elseif($attributeInfo.Type -eq 'Boolean'){
            if($Value -eq '1' -or $Value -eq 'true'){
                return $true
            }else{
                return $false
            }
        }elseif($attributeInfo.Type -eq 'Collection'){
            throw 'Unsupported api mapping type'
        }elseif($attributeInfo.Type -eq 'File'){
            throw 'Unsupported api mapping type'
        }elseif($attributeInfo.Type -eq 'Item'){
            throw 'Unsupported api mapping type'
        }elseif($attributeInfo.Type -eq 'ItemSet'){
            throw 'Unsupported api mapping'
        }elseif($attributeInfo.Type -eq 'TimeRanges'){
            throw 'Unsupported api mapping type'
        }else{
            return ""
        }
    }
}
Using module .\Endpoint.psm1
#Using module ..\Entity\Hotdesking.psm1

Class HotdeskingListEndpoint : Endpoint
{
    
    HotdeskingListEndpoint($APIConnection) : base($APIConnection)
    {
        $this.SetEndpointPath('HotdeskingList')
    }

    [PSObject] New([String] $mac, [String] $model) 
    { 
        return ($this.New($mac, $model, @{})) 
    }
    [PSObject] New([String] $mac, [String] $model, $options)
    {
        $payload = $this.GetNewPayload($mac, $model);
        $response =  $this.APIConnection.post($this.GetEndpointPath('new'), $payload)
        return $this.FormatResponse( $response, $options)
    }

    [PSObject] Update( $entity, $PropertyPath, $Value)
    {
        $Value = $this.ConvertToType($entity, $PropertyPath, $Value);
        $payload = $this.GetUpdatePayload( $entity, $PropertyPath, $Value )
        return $this.APIConnection.post('edit/update', @{'Body' = ($payload | ConvertTo-Json -Depth 10)} )
    }

    [PSObject] Save($extension)
    {
        return $this.APIConnection.post('edit/save', @{'Body' = ($extension.Id | ConvertTo-Json )})
    }

    # Functions used to convert CSV information for updates
    [hashtable] GetUpdatePayload( $entity, $PropertyPathString, $value ){
        [Collections.ArrayList] $PropertyPath = @();
        foreach($Path in $PropertyPathString.split('.'))
        {
            $PathObject = @{Name = $Path};
            # If it is a collection, get the collection ID
            if($entity.object.$Path.type -eq 'Collection')
            {
                $PathObject.IdInCollection = $entity.object.$Path._value.Id
            }
            $PropertyPath.Add( $PathObject )
        }
        $payload = @{
            "Path" = @{
                "ObjectId" = $entity.Id
                "PropertyPath" = $PropertyPath #$Mapping.ParsedConfig.$CSVHeader
            }
            "PropertyValue" = $value
        }
        return $payload
    }

    # Functions used to convert CSV information for updates
    [hashtable] GetNewPayload( $mac, $model ){
        $payload = @{
            "Body" = 
            @{
                "mac" = $mac
                "model" = $model
            } | ConvertTo-Json
        }
        return $payload
    }
}
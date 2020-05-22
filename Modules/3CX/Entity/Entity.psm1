Using module ..\Endpoints\Endpoint.psm1

Class Entity
{
    [Endpoint] $_endpoint
    [int64] $Id
    $object = @{}
    

    Entity($object, $endpoint)
    {
        $this.Id = $object.Id
        $this.object = $object.ActiveObject
        $this._endpoint = $endpoint
    }

    #$MappingParsedConfig
    # Return appropriate selected values based on type
    [PSObject] GetObjectValue( $attributeInfo )
    {
        #$attributeInfo = $this.GetObjectAttributeInfo($MappingParsedConfig.Values)
        if($attributeInfo.Type -in ('Enum', 'File', 'ItemSet')){
            return $attributeInfo.selected
        }else{
            return $attributeInfo._value
        }
    }

    # Return attributeInfo of a path from the object
    [PSObject] GetObjectAttributeInfo($key)
    {
        if( $key -is [string] ){
            $p1,$p2 = $key.Split(".")
        }elseif( $key -is [array] ){
            $p1, $p2 = $key
        }else{
            return $false
        }
        if($p2) {
            return $this.GetObjectAttributeInfo($this.object.$p1, $p2)
        }
        else {
            return $this.object.$p1
        }
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

}
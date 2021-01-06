Using module ..\Endpoints\Endpoint.psm1
Using module ..\ValueType.psm1

Class Entity
{
    [Endpoint] $_endpoint
    [string] $id
    [boolean] $Dirty = $false
    $object

    Entity($object, $endpoint)
    {
        $this.id = $object.id
        $this._endpoint = $endpoint
        if($object.ActiveObject){
            $this.object = $object.ActiveObject
        }else{
            $this.object = $object
        }
    }

    #$MappingParsedConfig
    # Return appropriate selected values based on type
    [PSObject] GetObjectValue( $attributeInfo )
    {
        if($attributeInfo.Type -in ([ValueType]::Enum, [ValueType]::File, [ValueType]::ItemSet)){
            return $attributeInfo.selected
        }else{
            return $attributeInfo._value
        }
    }

    # Return attributeInfo of a path from the object
    [PSObject] GetObjectAttributeInfo($key)
    {
        return $this.GetObjectAttributeInfo($key, $this.object)
    }
    [PSObject] GetObjectAttributeInfo($key, $object)
    {
        if( $key -is [string] ){
            #$p1,$p2 = $key.Split(".")
            $p1, $p2 = $key.Split(".", 2)
        }elseif( $key -is [array] ){
            $p1, $p2 = $key
        }else{
            return $false
        }
        if( $object.$p1.type -eq [ValueType]::Collection ) {
                return $this.GetObjectAttributeInfo($p2, $object.$p1._value)
        }
        else {
            return $object.$p1
        }
    }

    # Functions used to convert CSV information for updates
    [hashtable] GetUpdatePayload( $PropertyPath, $CSVDataValue ){
        $payload = @{
            "Path" = @{
                "ObjectId" = $this.id
                "PropertyPath" = $PropertyPath #$Mapping.ParsedConfig.$CSVHeader
            }
            "PropertyValue" = $CSVDataValue
        }
        return $payload
    }

    SetDirty([boolean] $value)
    {
        $this.Dirty = $value
    }
    [boolean] GetDirty()
    {
        return $this.Dirty
    }
    [boolean] IsDirty()
    {
        return ($this.GetDirty() -eq $true)
    }

}
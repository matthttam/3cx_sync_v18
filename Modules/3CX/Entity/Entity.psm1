Using module ..\Endpoints\Endpoint.psm1
Using module ..\ValueType.psm1

Class Entity
{
    [Endpoint] $_endpoint
    [string] $id
    [boolean] $Dirty = $false
    $object

    [String] $SaveMessageSuccess = "An entity has been saved."
    [String] $SaveMessageFail = "Failed to save an entity."
    [String] $UpdateMessageSuccess = "An entity has been staged to update."
    [String] $UpdateMessageFail = "Failed to stage an entity for update."

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

    [String] GetSaveMessageSuccess()
    {        
        return $this.SaveMessageSuccess
    }

    [String] GetSaveMessageFail()
    {
        return $this.SaveMessageFail
    }

    # Saves the current entity via the api
    [PSObject] Save()
    {
        try{
            $response = $this._endpoint.Save( $this )
            Write-PSFMessage -Level Output -Message ($this.GetSaveMessageSuccess())
            return $response
        }catch{
            Write-PSFMessage -Level Critical -Message ($this.GetSaveMessageFail())
            return $false
        }
    }

    [String] GetUpdateMessageSuccess()
    {
        return $this.UpdateMessageSuccess
    }

    [String] GetUpdateMessageFail()
    {
        return $this.UpdateMessageFail
    }

    [PSObject] Update($PropertyPath, $CSVValue)
    {
        try{
            $response = $this._endpoint.Update($this.GetUpdatePayload($PropertyPath, $CSVValue))
            Write-PSFMessage -Level Output -Message ($this.GetUpdateMessageSuccess($args))
            return $response
        }catch{
            Write-PSFMessage -Level Critical -Message ($this.GetUpdateMessageFail($args)  )
            return $false
        }

    }

}
Using module ..\Endpoints\Endpoint.psm1
Using module ..\ValueType.psm1

Class Entity
{
    [Endpoint] $_endpoint
    [string] $id
    [boolean] $Dirty = $false
    [boolean] $New = $false
    [hashtable] $DirtyProperties = @{}
    $object

    Entity($object, $endpoint)
    {
        $this.SetID($object.id)
        $this.SetEndpoint($endpoint)
        $this.SetObject($object)
        $this.SetNew($this.GetObject().IsNew -eq $true)
    }

    #[PSObject] GetProperty($PropertyName){
        # Pull the Extension Value's attribute information (used for conversion)
    #    $CurrentValueAttributeInfo = $this.GetObjectAttributeInfo($PropertyName)

        # Pull the current extension's actual value based on the Attribute Info provided
    #    return $this.GetObjectValue($CurrentValueAttributeInfo)
    #}
    
    # Return appropriate selected values based on type
    [PSObject] GetObjectValue( $ExtensionPropertyValues )
    {
        $attributeInfo = $this.GetObjectAttributeInfo($ExtensionPropertyValues)
        if($attributeInfo.Type -in ([ValueType]::Enum, [ValueType]::File, [ValueType]::ItemSet)){
            return $attributeInfo.selected
        }else{
            return $attributeInfo._value
        }
    }

    # Recursively navigate the stored object by the PropertyValues from the mapping file and modify its stored value internally
    [void] SetObjectValue( [array] $PropertyValues, $Value){
        $this.SetObjectValue( $PropertyValues, $Value, $this.object )
    }
    [void] SetObjectValue( [array] $PropertyValues, $Value, [pscustomobject] $object){
        $first, $rest = $PropertyValues
        $attributeInfo = $this.GetObjectAttributeInfo($first, $object)
        if($attributeInfo.Type -in ([ValueType]::Enum, [ValueType]::File, [ValueType]::ItemSet)){
            $store = 'selected'
        }else{
            $store = '_value'
        }

        if ($rest) {
            $this.SetObjectValue($rest, $Value, $object.$first.$store )
        } else {
            $object.$first.$store = $Value
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
            $p1, $p2 = $key.Split(".", 2)
        }elseif( $key -is [array] ){
            $p1, $p2 = $key
        }else{
            return $false
        }
        #if( $object.$p1.type -in ( [ValueType]::Collection, [ValueType]::Item ) ) {
        if($p2){
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
                "PropertyPath" = $PropertyPath
            }
            "PropertyValue" = $CSVDataValue
        }
        return $payload
    }

    [void] SetDirty(){
        $this.SetDirty($true)
    }
    # Sets/Gets Dirty flag
    [void] SetDirty( [boolean] $value )
    {
        $this.Dirty = $value
    }
    [boolean] GetDirty()
    {
        return $this.Dirty
    }

    # Returns if object is dirty true/false
    [boolean] IsDirty()
    {
        return ($this.GetDirty() -eq $true)
    }

    # Sets/Gets ID
    [void] SetID($id){
        $this.id = $id
    }
    [string] GetID(){
        return $this.id
    }

    # Sets/Gets Endpoint
    [void] SetEndpoint($endpoint){
        $this._endpoint = $endpoint
    }
    [string] GetEndpoint(){
        return $this._endpoint
    }

    # Sets/Gets Object
    [void] SetObject($object){
        if($object.ActiveObject){
            $this.object = $object.ActiveObject
        }else{
            $this.object = $object
        }
    }
    [PSObject] GetObject(){
        return $this.object
    }

    # Sets/Gets New
    [void] SetNew(){
        $this.SetNew($true)
    }
    [void] SetNew([boolean] $value){
        $this.New = $value
    }
    [boolean] GetNew(){
        return $this.New
    }
    [boolean] IsNew(){
        return $this.New -eq $true
    }


    # Sets/Gets DirtyProperties
    [void] SetDirtyProperties( [hashtable] $value){
        $this.DirtyProperties = $value
    }
    [PSObject] GetDirtyProperties(){
        return $this.DirtyProperties
    }
    [PSObject] GetDirtyProperties([string] $key){
        return ( $this.GetDirtyProperties() )[$key]
    }
    [PSObject] GetDirtyPropertiesNewValue([string] $key){
        return ( $this.GetDirtyProperties() )[$key]['NewValue']
    }
    [PSObject] GetDirtyPropertiesOldValue($key){
        return ( $this.GetDirtyProperties() )[$key]['OldValue']
    }
    [Array] GetDirtyPropertiesPropertyPath($key){
        return ( $this.GetDirtyProperties() )[$key]['PropertyPath']
    }
    [void] AddDirtyProperties($key, $value){
        if($this.DirtyProperties.keys -contains $key){
            $this.DirtyProperties[$key] = $value
        }else{
            $this.DirtyProperties.Add( $key ,  $value)
        }
    }
    [void] ClearDirtyProperties(){
        $this.SetDirtyProperties(@{})
        $this.SetDirty($false)
    }

    # Sets the object in 3CX which pulls additional information
    [PSObject] Set($SuccessMessage = "An entity has been set.", $FailMessage = "Failed to set an entity."){
        try{
            $response = $this._endpoint.set( @{"id" = $this.GetID()} )
            $this.SetObject( $response )
            Write-PSFMessage -Level Output -Message ($SuccessMessage)
            return $response
        }catch{
            Write-PSFMessage -Level Critical -Message ($FailMessage)
            return $false
        }
    }
    
    # Saves the current entity via the api
    [PSObject] Save($SuccessMessage = "An entity has been saved.", $FailMessage = "Failed to save an entity.")
    {
        $this.Set()
        $this.WriteStagedUpdates()
        try{
            $response = $this._endpoint.Save( $this )
            Write-PSFMessage -Level Output -Message ($SuccessMessage)
            return $response
        }catch{
            Write-PSFMessage -Level Critical -Message ($FailMessage)
            return $false
        }
    }

    # Perform update commands on all staged updates
    [void] WriteStagedUpdates(){
        $this.Set()
        try{
            foreach($key in $this.GetDirtyProperties().keys ){
                $response = $this.Update($this.GetDirtyPropertiesPropertyPath($key), $this.GetDirtyPropertiesNewValue($key))
            }
            $this.ClearDirtyProperties()
        }catch{
            Write-PSFMessage -level Critical -Message ('An unexpected error has occured while writing staged updates to 3CX')
        }
    }

    # Perform an update command
    [PSObject] Update($PropertyPath, $CSVValue){
        return Update($PropertyPath, $CSVValue, "An entity has been staged to update.", "Failed to stage an entity for update.")
    }
    [PSObject] Update($PropertyPath, $CSVValue, $SuccessMessage, $FailMessage)
    {
        try{
            $response = $this._endpoint.Update($this.GetUpdatePayload($PropertyPath, $CSVValue))
            Write-PSFMessage -Level Output -Message ($SuccessMessage)
            return $response
        }catch{
            Write-PSFMessage -Level Critical -Message ($FailMessage)
            return $false
        }
    }

    # Stage an update on this object
    [void] StageUpdate([Array] $PropertyValues, $CSVValue){
        $value = @{'PropertyPath' = $PropertyValues; 'OldValue' = $this.GetObjectValue($PropertyValues); 'NewValue' = $CSVValue}
        $this.AddDirtyProperties( ($PropertyValues -join '.') , $value)
        $this.SetObjectValue($PropertyValues, $CSVValue)
        $this.SetDirty()
    }

    # Clears all staged updates and resets the object
    [void] CancelUpdate(){
        foreach($PropertyValues in $this.DirtyProperties.Keys){
            $this.SetObjectValue( $PropertyValues.Split('.'), $this.DirtyProperties.$PropertyValues.OldValue )
        }
        $this.ClearDirtyProperties()
        $this.DirtyProperties = @{}
    }

}
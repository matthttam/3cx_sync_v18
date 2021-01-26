Using module ..\Endpoints\Endpoint.psm1
Using module ..\ValueType.psm1

Class Entity
{
    [Endpoint] $_endpoint
    [string] $ID # ID Used to set the object to be edited
    [string] $EditID # References the changed object. Used to read properties of object and save.
    [string] $ObjectID # Used to modify underlying values of an entity
    [boolean] $Dirty = $false
    [boolean] $New = $false
    [boolean] $Deleted = $false
    [hashtable] $DirtyProperties = @{}
    $object

    Entity($object, $endpoint)
    {
        $this.SetID($object.ID)
        $this.SetEndpoint($endpoint)
        $this.SetObject($object)
        $this.SetNew($this.GetObject().IsNew -eq $true)
    }

    [string] GetIdentifier(){
        return ('Entity ID: {0}, EditID: {1}' -f $this.GetID(), $this.GetEditID())
    }

    # Attempts to return a key's value from the object
    [PSObject] Get([string] $Key){
        try{          
            return $this.object.$Key._value
        }catch{
            Write-Error ('Failed to get value of key {0} from object: {1} ' -f $Key, $PSItem.Exception.Message) -ErrorAction Stop
            return $false
        }
        
    }
    
    # Return appropriate selected values based on type
    [PSObject] GetObjectValue( $ExtensionPropertyValues )
    {
        $attributeInfo = $this.GetObjectAttributeInfo($ExtensionPropertyValues)
        $store = $this.GetObjectValuePropertyName($attributeInfo)
        if($store -eq ''){
            return $attributeInfo
        }else{
            return $attributeInfo.$store
        }
    }

    # Recursively navigate the stored object by the PropertyValues from the mapping file and modify its stored value internally
    [void] SetObjectValue( [array] $PropertyValues, $Value){
        $this.SetObjectValue( $PropertyValues, $Value, $this.object )
    }

    [void] SetObjectValue( [array] $PropertyValues, $Value, [pscustomobject] $object){
        $first, $rest = $PropertyValues
		$store = $this.GetObjectValuePropertyName( $this.GetObjectAttributeInfo($first, $object) )
		if($store -eq ''){
			$object.$first = $Value
		}else{
			if ($rest) {
            $this.SetObjectValue($rest, $Value, $object.$first.$store )
			} else {
				$object.$first.$store = $Value
			}
		}
    }
	
	[string] GetObjectValuePropertyName($attributeInfo){
        # If it is a basic type, nothing to drill down to
        if($attributeInfo -is [string] -or $attributeInfo -is [int64] -or $attributeInfo -is [boolean]){
            return ''
        }
        # If it is Object type or Type is missing, nothing to drill down to
        if($attributeInfo.Type -in ([ValueType]::Object) -or  $null -eq ($attributeInfo | Get-Member -name 'type')){
            return ''
        }
        # Check if it needs selected or _value
		if($attributeInfo.Type -in ([ValueType]::Enum, [ValueType]::File, [ValueType]::ItemSet)){
            return 'selected'
        }else{
            return '_value'
        }
	}

    # Return attributeInfo of a path from the object
    [PSObject] GetObjectAttributeInfo([string] $key)
    {
        return $this.GetObjectAttributeInfo([string] $key, $this.object)
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
        if($p2){
                return $this.GetObjectAttributeInfo($p2, $object.$p1._value)
        }
        else {
            return $object.$p1
        }
    }

    # Functions used to convert CSV information for updates
    [hashtable] GetUpdatePayload( $PropertyPath, $Value ){
        $FormattedPropertyPath = [Collections.ArrayList] @()
        foreach($Path in $PropertyPath.Split('.') ){
            $FormattedPath = @{'Name' = $Path}
            $AttributeInfo = $this.GetObjectAttributeInfo($Path)
            if($AttributeInfo.type -eq [ValueType]::Collection){
                $FormattedPath.IdInCollection = $AttributeInfo._value[$Value.CollectionIndex]
                # A collection index will need to be set somehow to handle collections
            }
            $FormattedPropertyPath += $FormattedPath
        }
        
        $payload = @{
            "Path" = @{
                "ObjectId" = $this.GetEditID()
                "PropertyPath" = $FormattedPropertyPath
            }
            "PropertyValue" = $Value
        }
        return $payload
    }

    # Sets/Gets Dirty flag
    [void] SetDirty(){ $this.SetDirty($true) }
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

    # Sets/Gets Deleted flag
    [void] SetDeleted(){ $this.SetDeleted($true) }
    [void] SetDeleted( [boolean] $value )
    {
        $this.Deleted = $value
    }
    [boolean] GetDeleted()
    {
        return $this.Deleted
    }

    # Returns if object is dirty true/false
    [boolean] IsDeleted()
    {
        return ($this.GetDeleted() -eq $true)
    }

    # Sets/Gets ID
    [void] SetID($ID){
        $this.ID = $ID
    }
    [string] GetID(){
        return $this.ID
    }

    # Sets/Gets SaveID (Used for save)
    [void] SetEditID($ID){
        $this.EditID = $ID
    }
    [string] GetEditID(){
        return $this.EditID
    }

    # Sets/Gets ObjectID (Used for update commands)
    [void] SetObjectID($ID){
        $this.ObjectID = $ID
    }
    [string] GetObjectID(){
        return $this.ObjectID
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
        if($this.object.id){
            $this.SetObjectId($This.object.id)
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
        return ( $this.GetDirtyProperties() )[$key].NewValue
    }
    [PSObject] GetDirtyPropertiesOldValue($key){
        return ( $this.GetDirtyProperties() )[$key].OldValue
    }
    [Array] GetDirtyPropertiesPropertyPath($key){
        return ( $this.GetDirtyProperties() )[$key].PropertyPath
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
    [void] Set($SuccessMessage = "An entity has been set.", $FailMessage = "Failed to set an entity."){
        try{
            # New objects are already set with a template and need only the ID Updated
            if($this.IsNew()){
                $response = $this._endpoint.New()
                $this.SetID($response.Id)
                $this.SetObjectValue('Id', $response.ActiveObject.Id)
            }else{
                $response = $this._endpoint.set( @{"Id" = $this.GetID()} )
                if($response.Id){
                    $this.SetEditID($response.Id)
                }
                $this.SetObject( $response )
            }
            
            Write-PSFMessage -Level Debug -Message ($SuccessMessage)
        }catch{
            Write-PSFMessage -Level Critical -Message ($FailMessage)
        }
    }
    
    # Saves the current entity via the api
    # Calls set
    [void] Save($SuccessMessage = "An entity has been saved.", $FailMessage = "Failed to save an entity.")
    {
        $this.Set()
        $this.CommitStagedUpdates()
        if ( $PSCmdlet.ShouldProcess($this.GetIdentifier(), 'Save') ){
            try{
                $this._endpoint.Save( $this ) | Out-Null
                Write-PSFMessage -Level Output -Message ($SuccessMessage)
            }catch{
                Write-PSFMessage -Level Critical -Message ($FailMessage)
            }
        }
    }

    # Perform update commands on all staged updates
    # Assumes set has already been called
    [void] CommitStagedUpdates(){
        if ( $PSCmdlet.ShouldProcess($this.GetIdentifier(), 'CommitStagedUpdates') ){
            try{
                foreach($key in $this.GetDirtyProperties().keys ){
                    foreach($Value in $this.GetDirtyPropertiesNewValue($key)){
                        $this.Update($this.GetDirtyPropertiesPropertyPath($key), $Value) | Out-Null
                    }
                }
            $this.ClearDirtyProperties()
            }catch{
                Write-PSFMessage -level Critical -Message ('An unexpected error has occured while writing staged updates to 3CX')
            }
        }
    }

    # Perform an update command
    [void] Update($PropertyPath, $Value){
        Update($PropertyPath, $Value, "An entity has been staged to update.", "Failed to stage an entity for update.")
    }
    [void] Update($PropertyPath, $Value, $SuccessMessage, $FailMessage)
    {
        if ( $PSCmdlet.ShouldProcess($this.GetIdentifier(), 'Update') ){
            try{
                $this._endpoint.Update($this.GetUpdatePayload($PropertyPath, $Value)) | Out-Null
                Write-PSFMessage -Level Output -Message ($SuccessMessage)
            }catch{
                Write-PSFMessage -Level Critical -Message ($FailMessage)
            }
        }
    }

    #[void] StageUpdate([Array] $PropertyValues, $CSVValue){
    #    StageUpdate([Array] $PropertyValues, $CSVValue, $null)
    #}
    # Stage an update on this object
    [void] StageUpdate([Array] $PropertyValues, $Value){
        # If the property passed is of an object type then we need to store things differently
        $value = @{'PropertyPath' = $PropertyValues; 'OldValue' = $this.GetObjectValue($PropertyValues); 'NewValue' = $Value}
        if( -NOT $this.GetObjectValue($PropertyValues).type -eq [ValueType]::Object ){
            $this.SetObjectValue($PropertyValues, $Value)
        }
        $this.AddDirtyProperties( ($PropertyValues -join '.') , $value)
        $this.SetDirty()
    }

    # Clears all staged updates and resets the object
    [void] Cancel(){
        $this._endpoint.Cancel()
        $this.ClearDirtyProperties()
    }

}
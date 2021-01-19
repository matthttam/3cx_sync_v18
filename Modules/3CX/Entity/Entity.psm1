Using module ..\Endpoints\Endpoint.psm1
Using module ..\ValueType.psm1

Class Entity
{
    [Endpoint] $_endpoint
    [string] $id
    [boolean] $Dirty = $false
    [boolean] $New = $false
    [boolean] $Deleted = $false
    [hashtable] $DirtyProperties = @{}
    $object

    Entity($object, $endpoint)
    {
        $this.SetID($object.id)
        $this.SetEndpoint($endpoint)
        $this.SetObject($object)
        $this.SetNew($this.GetObject().IsNew -eq $true)
    }

    [string] GetIdentifier(){
        return ('Entity ID: {0}, ObjectID: {1}' -f $this.GetID(), $this.GetObjectID())
    }

    [string] GetObjectID(){
        return $this.GetObjectValue('id')
    }

    # Attempts to run 
    [PSObject] Get([string] $Key){
        #$command = '$this.' + $Key + '()'
        try{          
            #return (Invoke-Expression -Command $command)
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
    [void] SetID($id){
        $this.id = $id
    }
    [string] GetID(){
        return $this.id
    }
    [void] SetObjectId($id){

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
    [void] Set($SuccessMessage = "An entity has been set.", $FailMessage = "Failed to set an entity."){
        try{
            # New objects are already set with a template and need only the ID Updated
            if($this.IsNew()){
                $response = $this._endpoint.New()
                $this.SetID($response.Id)
                $this.SetObjectValue('id', $response.ActiveObject.id)
            }else{
                $response = $this._endpoint.set( @{"id" = $this.GetID()} )
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
                    $this.Update($this.GetDirtyPropertiesPropertyPath($key), $this.GetDirtyPropertiesNewValue($key)) | Out-Null
                }
            $this.ClearDirtyProperties()
            }catch{
                Write-PSFMessage -level Critical -Message ('An unexpected error has occured while writing staged updates to 3CX')
            }
        }
    }

    # Perform an update command
    [void] Update($PropertyPath, $CSVValue){
        Update($PropertyPath, $CSVValue, "An entity has been staged to update.", "Failed to stage an entity for update.")
    }
    [void] Update($PropertyPath, $CSVValue, $SuccessMessage, $FailMessage)
    {
        if ( $PSCmdlet.ShouldProcess($this.GetIdentifier(), 'Update') ){
            try{
                $this._endpoint.Update($this.GetUpdatePayload($PropertyPath, $CSVValue)) | Out-Null
                Write-PSFMessage -Level Output -Message ($SuccessMessage)
            }catch{
                Write-PSFMessage -Level Critical -Message ($FailMessage)
            }
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
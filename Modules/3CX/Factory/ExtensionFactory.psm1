Using module ..\APIConnection.psm1
Using module .\EntityFactory.psm1
Using module ..\Endpoints\ExtensionListEndpoint.psm1
Using module ..\Entity\Extension.psm1

Class ExtensionFactory : EntityFactory
{
    Static [Extension[]] $Extensions
    [ExtensionListEndpoint] $_endpoint
    $EndpointName = 'ExtensionListEndpoint'

    ExtensionFactory([APIConnection] $Connection) : base( $Connection ){

    }

    # Get all extensions and return them as an array of extensions
    [Extension[]] GetExtensions()
    {
        $ExtensionList = $this._endpoint.Get() | Select-Object -ExpandProperty 'list'
        return $this.makeExtension($ExtensionList)
    }

    # Create extension objects from an array of extension objects
    [Extension[]] makeExtension([PSObject[]] $objects){
        $return = @()
        foreach($object in $objects)
        {
            $return += $this.makeExtension($object)
        }
        return $return
    }

    #Create an instance of a single extension using a provided object
    [Extension] makeExtension([PSObject] $object)
    {
        return [Extension]::new($object, $this._endpoint)
    }

    # Create extension based on a specific ID
    # If a 32 bit integer is passed convert to 64 bit.
    [Extension] makeExtension([int32] $id){ return $this.makeExtension([int64] $id)}
    [Extension] makeExtension([Int64] $id)
    {
        $ExtensionList = $this._endpoint.Get() | Select-Object -ExpandProperty 'list'
        $object = $ExtensionList | Where-Object {$_.id -eq $id}
        if($object){
            return [Extension]::new($object, $this._endpoint)
        }else{
            return $false
        }
    }

    # Create an empty extension as new object
    [Extension] makeExtension()
    {
        $responseObject = $this._endpoint.New()
        return [Extension]::new($responseObject, $this._endpoint)
    }

}
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

    #Create an instance of a single extension
    [Extension] makeExtension([PSObject] $object)
    {
        return [Extension]::new($object, $this._endpoint)
    }

    # Create extension objects from an array of extension objects
    [Extension[]] makeExtension([Array] $objects){
        $return = @()
        foreach($object in $objects)
        {
            $return += $this.makeExtension($object)
        }
        return $return
    }

    # Create extension based on specific ID
    [Extension] makeExtension([string] $id)
    {
        $payload = @{"id" = $id}
        $responseObject = $this._endpoint.set($payload)
        return [Extension]::new($responseObject, $this._endpoint)
    }

    # Create extension as new object
    [Extension] makeExtension()
    {
        $responseObject = $this._endpoint.New()
        return [Extension]::new($responseObject, $this._endpoint)
    }

    # Get all extensions and return them as an array of extensions
    [Extension[]] getExtensions()
    {
        $ExtensionList = $this._endpoint.Get() | Select-Object -ExpandProperty 'list'
        return $this.makeExtension($ExtensionList)
    }
}
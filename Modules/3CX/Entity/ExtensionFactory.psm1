Using module ..\Endpoints\ExtensionListEndpoint.psm1
Using module .\Extension.psm1

Class ExtensionFactory
{
    Static [Extension[]] $Extensions
    [ExtensionListEndpoint] $_endpoint

    ExtensionFactory([ExtensionListEndpoint] $endpoint)
    {
        $this._endpoint = $endpoint
    }

    #Create an instance of a single extension
    [Extension] makeExtension([PSObject] $object)
    {
        return [Extension]::new($object, $this._endpoint)
    }

    # Create extension objects from an array of extension objects
    [Array] makeExtension([Array] $objects){
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
        #$response = $this._endpoint.set($payload)
        #$responseObject = $response.content | ConvertFrom-Json -ErrorAction Stop
        return [Extension]::new($responseObject, $this._endpoint)
    }

    # Create extension as new object
    [Extension] makeExtension()
    {
        $responseObject = $this._endpoint.New()
        #$response = $this._endpoint.New()
        #$responseObject = $response.content | ConvertFrom-Json -ErrorAction Stop
        return [Extension]::new($responseObject, $this._endpoint)
    }
}
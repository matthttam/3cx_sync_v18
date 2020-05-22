Using module ..\Endpoints\ExtensionList.psm1
Using module .\Extension.psm1

Class ExtensionFactory
{
    Static [Extension[]] $Extensions
    [ExtensionList] $_endpoint

    ExtensionFactory([ExtensionList] $endpoint)
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
        $response = $this._endpoint.set($payload)
        $responseObject = $response.content | ConvertFrom-Json -ErrorAction Stop
        return [Extension]::new($responseObject, $this._endpoint)
    }

    # Create extension as new object
    [Extension] makeExtension()
    {
        Write-Output 'here';
        $response = $this._endpoint.New()
        $responseObject = $response.content | ConvertFrom-Json -ErrorAction Stop
        return [Extension]::new($responseObject, $this._endpoint)
    }
}
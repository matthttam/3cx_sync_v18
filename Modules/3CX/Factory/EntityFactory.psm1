Using module ..\Endpoints\Endpoint.psm1
Using module ..\Entity\Entity.psm1

Class EntityFactory
{
    Static [Entity[]] $Entities
    [Endpoint] $_endpoint

    ExtensionFactory([Endpoint] $endpoint)
    {
        $this._endpoint = $endpoint
    }
}
Using module ..\APIConnection.psm1
Using module ..\Endpoints\Endpoint.psm1
Using module ..\Entity\Entity.psm1

Class EntityFactory
{
    #Static [Entity[]] $Entities
    #[Endpoint] $_endpoint
    #[String] $EndpointName

    EntityFactory([APIConnection] $Connection)
    {
        $this._endpoint = $Connection.endpoints.($this.EndpointName)
    }
}
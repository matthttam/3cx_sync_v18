Using module ..\APIConnection.psm1
Using module ..\Endpoints\Endpoint.psm1
Using module ..\Entity\Entity.psm1

Using module ..\Endpoints\ExtensionListEndpoint.psm1
Using module ..\Endpoints\GroupListEndpoint.psm1
Using module ..\Endpoints\HotdeskingListEndpoint.psm1

Class EntityFactory
{
    EntityFactory([APIConnection] $Connection)
    {
        $this._endpoint = New-Object -TypeName $this.EndpointName -ArgumentList $Connection
    }
}
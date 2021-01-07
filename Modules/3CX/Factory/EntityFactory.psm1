Using module ..\APIConnection.psm1
Using module ..\Endpoints\Endpoint.psm1
Using module ..\Entity\Entity.psm1

Using module .\Modules\3CX\Endpoints\ExtensionListEndpoint.psm1
Using module .\Modules\3CX\Endpoints\GroupListEndpoint.psm1
Using module .\Modules\3CX\Endpoints\HotdeskingListEndpoint.psm1

Class EntityFactory
{
    #Static [Entity[]] $Entities
    #[Endpoint] $_endpoint
    #[String] $EndpointName

    EntityFactory([APIConnection] $Connection)
    {
        $this._endpoint = New-Object -TypeName $this.EndpointName -ArgumentList $Connection
        #[$this.EndpointName]::new($Connection)
        #$this._endpoint = $Connection.endpoints.($this.EndpointName)
    }
}
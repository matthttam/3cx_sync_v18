Using module .\Endpoint.psm1

Class GroupListEndpoint : Endpoint
{
    
    GroupListEndpoint($APIConnection) : base($APIConnection)
    {
        $this.SetEndpointPath('GroupList')
    }

}
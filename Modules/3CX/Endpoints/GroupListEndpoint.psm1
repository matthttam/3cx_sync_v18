Using module .\Endpoint.psm1

Class GroupListEndpoint : Endpoint
{
    
    GroupListEndpoint($APIConnection) : base($APIConnection)
    {
        $this.SetEndpointPath('GroupList')
    }

    [PSObject] Update($payload)
    {
        return $this.APIConnection.post('edit/update', @{'Body' = ($payload | ConvertTo-Json -Depth 10)} )
    }

    [PSObject] Save($group)
    {
        return $this.APIConnection.post('edit/save', @{'Body' = ($group.Id | ConvertTo-Json )})
    }

}
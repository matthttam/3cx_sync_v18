Using module .\Endpoint.psm1

Class ExtensionListEndpoint : Endpoint
{
    
    ExtensionListEndpoint($APIConnection) : base($APIConnection)
    {
        $this.SetEndpointPath('ExtensionList')
    }

    [PSObject] Update($payload)
    {
        return $this.APIConnection.post('edit/update', @{'Body' = ($payload | ConvertTo-Json -Depth 10)} )
    }

    [PSObject] Save($extension)
    {
        return $this.APIConnection.post('edit/save', @{'Body' = ($extension.Id | ConvertTo-Json -Depth 10)})
    }
}
Using module .\Endpoint.psm1

Class ExtensionList : Endpoint
{
    
    ExtensionList($APIConnection) : base($APIConnection)
    {
    }

    [PSObject] New()
    {
        return $this.APIConnection.post('ExtensionList/new')
    }

    [PSObject] Set($payload)
    {
        return $this.APIConnection.post('ExtensionList/set', @{'Body' = ($payload | ConvertTo-Json )})
    }

    [PSObject] Update($payload)
    {
        return $this.APIConnection.post('edit/update', @{'Body' = ($payload | ConvertTo-Json -Depth 10)} )
    }

    [PSObject] Save($extension)
    {
        return $this.APIConnection.post('edit/save', @{'Body' = ($extension.Id | ConvertTo-Json )})
    }

    [PSObject] Get()
    {
        return $this.APIConnection.get('ExtensionList')
    }
}
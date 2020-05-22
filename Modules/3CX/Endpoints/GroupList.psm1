Using module .\Endpoint.psm1

Class GroupList : Endpoint
{
    
    GroupList($APIConnection) : base($APIConnection)
    {
    }

    [PSObject] New()
    {
        return $this.APIConnection.post('GroupList/new')
    }

    [PSObject] Set($payload)
    {
        return $this.APIConnection.post('GroupList/set', @{'Body' = ($payload | ConvertTo-Json )})
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
        return $this.APIConnection.get('GroupList')
    }
}
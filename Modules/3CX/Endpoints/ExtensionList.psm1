Using module .\Endpoint.psm1

Class ExtensionList : Endpoint
{
    
    ExtensionList($APIConnection) : base($APIConnection)
    {
    }

    [Microsoft.PowerShell.Commands.WebResponseObject] New()
    {
        return $this.APIConnection.post('ExtensionList/new')
    }

    [Microsoft.PowerShell.Commands.WebResponseObject] Set()
    {
        return $this.APIConnection.post('ExtensionList/set')
    }

    [Microsoft.PowerShell.Commands.WebResponseObject] Update($payload)
    {
        return $this.APIConnection.post('edit/update', @{'Body' = ($payload | ConvertTo-Json -Depth 10)} )
    }

    [Microsoft.PowerShell.Commands.WebResponseObject] Save($extension)
    {
        return $this.APIConnection.post('edit/save', @{'Body' = ($extension.Id | ConvertTo-Json )})
    }

    [Microsoft.PowerShell.Commands.WebResponseObject] Get()
    {
        return $this.APIConnection.get('ExtensionList')
    }
}
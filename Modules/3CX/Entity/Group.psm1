Using module .\Entity.psm1
Using module ..\Endpoints\GroupListEndpoint.psm1

Class Group : Entity
{
    [GroupListEndpoint] $_endpoint
    [Hashtable] $Members = @{}
    [Hashtable] $PossibleValueLookup = @{}

    Group($object, $endpoint) : base($object, $endpoint)
    {
        $this.Members.Selected = $this.QueryAllMembers()
        #$this.Members.possibleValues = $this.QueryAllPossibleValues()
        #if($this.GetPossibleValues()){
        #    $this.SetPossibleValueLookup($this.GetPossibleValues())
        #}
    }

    # Query for all possible values by calling QueryPOssibelValues with empty search
    [PSObject] QueryPossibleValues()
    {
        return $this.QueryPossibleValues("")
    }
    # Searches by ID
    # Returns only the item by its ID or Null
    [PSObject] QueryPossibleValuesByNumber([string] $search)
    {
        $results = $this.QueryPossibleValues($search)
        return (($results | Where-Object -filterScript {$_.Number._value -eq "$search"}), $false -ne $null)[0]
    }
    # Allow a specific search
    # Returns an array
    [PSObject] QueryPossibleValues([string] $search)
    {
        $state = @{"Start" = 0; "SortBy" = $null; "Reverse" = $false; "Search" = $search}
        return $this.QueryPossibleValues($state)
    }
    # Perform actual query on endpoint using this object and the state
    [PSObject] QueryPossibleValues([Hashtable] $state)
    {
        return $this._endpoint.QueryPossibleValues( $this, $state )
    }
    # Alias for QueryPosisbleValues()
    [PSObject] QueryAllPossibleValues()
    {
        return $this.QueryPossibleValues()
    }

    <#PSObject] QueryAllPossibleValues()
    {
        return $this._endpoint.QueryAllPossibleValues( $this )
    }#>

    [PSObject] QueryMembers()
    {
        
        return $this.QueryMembers("")
    }
    [PSObject] QueryMembersByNumber([string] $search)
    {
        $results = $this.QueryMembers($search)
        return ( ($results | Where-Object -filterScript {$_.Number._value -eq "$search"}), $false -ne $null)[0]
    }
    [PSObject] QueryMembers([string] $search)
    {
        $state = @{"Start" = 0; "SortBy" = $null; "Reverse" = $false; "Search" = $search}
        return $this.QueryMembers($state)
    }
    [PSObject] QueryMembers([Hashtable] $state)
    {
        return $this._endpoint.QueryMembers( $this, $state )
    }
    [PSObject] QueryAllMembers()
    {
        return $this.QueryMembers()
        #return $this._endpoint.QueryAllMembers( $this )
    }

    [PSObject] GetSelected()
    {
        return $this.Members.selected
    }
    [PSObject] GetSelectedByNumber($number)
    {
        return $this.Members.selected | Where-Object -FilterScript {$_.Number._value -eq (""+$number)}
    }

    [String] GetRemoveMembersMessage([array] $members)
    {
        $MessageInfoTemplate = @{label="Info";expression={$_.Number._value + ' - ' + $_.FirstName._value + ' ' + $_.LastName._value}}
        $ExtensionToAddInfo = $members | Select-Object -Property $MessageInfoTemplate | Select-Object -ExpandProperty Info
        $message = ("Staged Update to Group '{0}' to Remove Extension(s) '{1}'" -f $this.GetName(), ($ExtensionToAddInfo -join "', '"))
        return $message
    }
    [PSObject] RemoveMembers($members)
    {
        try{
            Write-PSFMessage -Level Output -Message ($this.GetRemoveMembersMessage($members))
            return $this._endpoint.RemoveMembers( $this, $members )
        }catch{
            Write-PSFMessage -Level Critical -Message ("Failed to Update Group '{0}' due to a staging error." -f ($this.GetName()))
            return $null
        }
    }

    [String] GetAddMembersMessage([array] $members)
    {
        $MessageInfoTemplate = @{label="Info";expression={$_.Number._value + ' - ' + $_.FirstName._value + ' ' + $_.LastName._value}}
        $ExtensionToAddInfo = $members | Select-Object -Property $MessageInfoTemplate | Select-Object -ExpandProperty Info
        $message = ("Staged Update to Group '{0}' to Add Extension(s) '{1}'" -f $this.GetName(), ($ExtensionToAddInfo -join "', '"))
        return $message
    }
    [PSObject] AddMembers($members)
    {
        try{
            Write-PSFMessage -Level Output -Message ($this.GetAddMembersMessage($members))
            return $this._endpoint.AddMembers( $this, $members )
        }catch{
            Write-PSFMessage -Level Critical -Message ("Failed to Update Group '{0}' due to a staging error." -f ($this.GetName()))
            return $null
        }
    }

    [String] GetSaveMessage()
    {
        $message = ("Group {0} has been saved." -f $this.GetName())
        return $message
    }
    
    [PSObject] Save()
    {
        try{
            Write-PSFMessage -Level Output -Message ($this.GetSaveMessage())
            return $this._endpoint.Save( $this )
        }catch{
            Write-PSFMessage -Level Critical -Message ("Failed to Update Group: '{0}'" -f $this.GetName() )
            return $false
        }
        
    }

    [string] GetName()
    {
        return $this.object.Name._value
    }

}
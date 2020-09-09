Using module .\Entity.psm1
Using module ..\Endpoints\GroupListEndpoint.psm1

Class Group : Entity
{
    [GroupListEndpoint] $_endpoint
    [Hashtable] $Members = @{}

    Group($object, $endpoint) : base($object, $endpoint)
    {
        $this.Members.Selected = $this.QueryAllMembers()
    }

    # Alias for QueryPosisbleValues()
    [PSObject] QueryAllPossibleValues()
    {
        return $this.QueryPossibleValues()
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

    # Alias for QueryMembers
    [PSObject] QueryAllMembers()
    {
        return $this.QueryMembers()
    }

    # Query for all selected members by calling QueryPOssibelValues with empty search
    [PSObject] QueryMembers()
    {
        return $this.QueryMembers("")
    }

    # Query selected members by number
    [PSObject] QueryMembersByNumber([string] $search)
    {
        $results = $this.QueryMembers($search)
        return ( ($results | Where-Object -filterScript {$_.Number._value -eq "$search"}), $false -ne $null)[0]
    }

    # Query members with search string
    [PSObject] QueryMembers([string] $search)
    {
        $state = @{"Start" = 0; "SortBy" = $null; "Reverse" = $false; "Search" = $search}
        return $this.QueryMembers($state)
    }

    # Query members with state hashtable
    [PSObject] QueryMembers([Hashtable] $state)
    {
        return $this._endpoint.QueryMembers( $this, $state )
    }

    # Return Members Selected attribute from this object (populated on creation)
    [PSObject] GetSelected()
    {
        return $this.Members.selected
    }

    # Return by number a specific member from the Members Selected attribute
    [PSObject] GetSelectedByNumber($number)
    {
        return $this.Members.selected | Where-Object -FilterScript {$_.Number._value -eq (""+$number)}
    }

    # Return string of message to use when members are removed.
    [String] GetRemoveMembersMessage([array] $members)
    {
        $MessageInfoTemplate = @{label="Info";expression={$_.Number._value + ' - ' + $_.FirstName._value + ' ' + $_.LastName._value}}
        $ExtensionToAddInfo = $members | Select-Object -Property $MessageInfoTemplate | Select-Object -ExpandProperty Info
        $message = ("Staged Update to Group '{0}' to Remove Extension(s) '{1}'" -f $this.GetName(), ($ExtensionToAddInfo -join "', '"))
        return $message
    }

    # Remove Members
    [PSObject] RemoveMembers($members)
    {
        try{
            
            $response = $this._endpoint.RemoveMembers( $this, $members )
            Write-PSFMessage -Level Output -Message ($this.GetRemoveMembersMessage($members))
            return $response
        }catch{
            Write-PSFMessage -Level Critical -Message ("Failed to Update Group '{0}' due to a staging error." -f ($this.GetName()))
            return $null
        }
    }

    # Return string of message to use when members are added.
    [String] GetAddMembersMessage([array] $members)
    {
        $MessageInfoTemplate = @{label="Info";expression={$_.Number._value + ' - ' + $_.FirstName._value + ' ' + $_.LastName._value}}
        $ExtensionToAddInfo = $members | Select-Object -Property $MessageInfoTemplate | Select-Object -ExpandProperty Info
        $message = ("Staged Update to Group '{0}' to Add Extension(s) '{1}'" -f $this.GetName(), ($ExtensionToAddInfo -join "', '"))
        return $message
    }

    # Add Members
    [PSObject] AddMembers($members)
    {
        try{
            
            $response = $this._endpoint.AddMembers( $this, $members )
            Write-PSFMessage -Level Output -Message ($this.GetAddMembersMessage($members))
            return $response
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
            
            $response = $this._endpoint.Save( $this )
            Write-PSFMessage -Level Output -Message ($this.GetSaveMessage())
            return $response
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
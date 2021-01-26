Using module .\Entity.psm1
Using module ..\Endpoints\GroupListEndpoint.psm1

[string]$LastSetID
Class Group : Entity
{
    [GroupListEndpoint] $_endpoint
    [String] $Name

    Group($object, $endpoint) : base($object, $endpoint)
    {
        $this.SetName($object.Name)
    }

    [string] GetIdentifier(){
        return ('Group Name: {0}, ID: {1}' -f $this.GetName(), $this.GetID())
    }
    
    # Query for all possible values by calling QueryPossibelValues with empty search
    [PSObject] QueryAllPossibleValues(){ return $this.QueryPossibleValues() }
    [PSObject] QueryPossibleValues()
    {
        return $this.QueryPossibleValues("")
    }

    [PSObject] QueryPossibleValuesByNumber([array] $search)
    {
        $return = [Collections.ArrayList] @()
        foreach($s in $search){
            $return += $this.QueryPossibleValuesByNumber($s)
        }
        return $return
    }

    # Searches by Number
    # Returns only the item by its Number or Null
    [PSObject] QueryPossibleValuesByNumber([string] $search)
    {
        $results = $this.QueryPossibleValues($search)
        $return = $results | Where-Object -filterScript {$_.Number._value -eq "$search"}
        if(-NOT $return){
            $return = $false
            Write-PSFMessage -Level Warning -Message ('Extension Number {0} not valid for group {1}' -f $search, $this.GetIdentifier() )
        }
        return $return
    }

    # Allow a specific search
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

    # Query for all selected members by calling QueryPOssibelValues with empty search
    [PSObject] QueryAllMembers(){ return $this.QueryMembers() }    
    [PSObject] QueryMembers()
    {
        return $this.QueryMembers("")
    }

    # Query selected members by number
    [PSObject] QueryMembersByNumber([string] $search)
    {
        $results = $this.QueryMembers($search)
        $return = $results | Where-Object -filterScript {$_.Number._value -eq "$search"}
        if(-Not $return){
            $return = $false
        }
        return $return
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
    [PSObject] GetMembersSelected()
    {
        # If the group hasn't populated all selected members
        # Determined by comparing the count of Members and count of Members.selected
        if($this.object.Members.count -eq 0 -or $this.object.Members.count -ne $this.object.Members.selected.count){
            $this.set()
            $this.object.Members.selected = $this.QueryAllMembers()
        }
        return $this.object.Members.selected
    }

    # Return by number a specific member from the Members Selected attribute
    [PSObject] GetMembersSelectedByNumber($number)
    {
        return $this.GetMembersSelected() | Where-Object -FilterScript {$_.Number._value -eq (""+$number)}
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
    [void] RemoveMembers($members)
    {
        if ( $PSCmdlet.ShouldProcess($this.GetIdentifier(), $this.GetRemoveMembersMessage($members)) )
        {
            try{
                $this._endpoint.RemoveMembers( $this, $members ) | Out-Null
                Write-PSFMessage -Level Output -Message ($this.GetRemoveMembersMessage($members))
            }catch{
                Write-PSFMessage -Level Critical -Message ("Failed to Update Group '{0}' due to a staging error." -f ($this.GetName()))
            }
        }
        $this.SetDirty()
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
    [void] AddMembers($members)
    {
        if ($PSCmdlet.ShouldProcess($this.GetIdentifier(), $this.GetAddMembersMessage($members)))
        {
            try{
                
                $this._endpoint.AddMembers( $this, $members ) | Out-Null
                Write-PSFMessage -Level Output -Message ($this.GetAddMembersMessage($members))
            }catch{
                Write-PSFMessage -Level Critical -Message ("Failed to Update Group '{0}' due to a staging error." -f ($this.GetName()))
            }
        }
        $this.SetDirty()
    }
    
    # Sets/Gets Model
    [void] SetName($Name){
        $this.Name = $Name
    }
    [string] GetName(){
        return $this.Name
    }

    [void] Set(){
        $script:LastSetID = $this.GetID()
        $this.Set(
            "Group '{0}' has been set." -f $this.GetIdentifier(),
            "Failed to set Group: '{0}'" -f $this.GetIdentifier()
        )
    }

    [void] Save(){
        $this.Save(
            "Group '{0}' has been saved." -f $this.GetIdentifier(),
            "Failed to save Group: '{0}'" -f $this.GetIdentifier()
        )
    }

    # Need to run some in-time code to get the appropriate IDs
   [void] CommitStagedUpdates(){
       if($this.GetDirtyProperties().keys -contains 'Members'){
           foreach( $MemberStagedUpdate in $this.DirtyProperties['Members']){
               foreach($key in $MemberStagedUpdate.keys){
                    $MemberStagedUpdate.$key.Ids = @($this.QueryPossibleValuesByNumber($MemberStagedUpdate[$key].Ids).Id)
                }
           }
       }
        foreach($key in $this.GetDirtyProperties().keys ){

        }
        ([Entity]$this).CommitStagedUpdates()
    }

    # Stage an update on this object
    [void] Update([Array] $PropertyValues, $Value){
        # If PropertyValues is @('Members')
        if($null -eq (Compare-Object $PropertyValues @('Members'))){
            # Return any numbers that should be added
            $MemberNumbersToAdd = ($Value | Where-Object { $_.Number -NotIn ($this.GetMembersSelected()).Number._value}).Number
            $MemberNumbersToDelete = ($this.GetMembersSelected() | Where-Object {$_.Number._value -NotIn $Value.Number} ).Number
            $Value = [Collections.ArrayList] @()
            if($MemberNumbersToAdd){
                $Value += @{'Add' = @{"Ids" = @($MemberNumbersToAdd); "IsAllSelected" = $false; "Search" = ""}}
            }
            if($MemberNumbersToDelete){
                $Value += @{'Delete' = @{"Ids" = @($MemberNumbersToDelete); "IsAllSelected" = $false; "Search" = ""}}
            }
            if($Value.count -eq 0){
                return
            }
        }
        ([Entity]$this).Update($PropertyValues, $Value)
    }



}
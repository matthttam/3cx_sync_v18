Using module .\Entity.psm1
Using module ..\Endpoints\GroupListEndpoint.psm1
Using module ..\CopyObject.psm1

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
<#
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
#>
    # Sets/Gets Model
    [void] SetName($Name){
        $this.Name = $Name
    }
    [string] GetName(){
        return $this.Name
    }

    [void] Set(){
        #$script:LastSetID = $this.GetID()
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

    # 
    <#[void] CommitStagedUpdates(){

        ([Entity]$this).CommitStagedUpdates()
    }#>

    # Returns an object containing the new value (possibly changed) and the comparison object
    [psobject] CompareMembershipByNumber($Numbers){
        #Remove numbers that need to be removed.
        $Value = [System.Collections.ArrayList] ($this.GetMembersSelected() | Where-Object {$_.Number._value -In $Numbers.Number} )
        $MemberNumbersToAdd = ($Numbers | Where-Object { $_.Number -NotIn $Value.Number._value}).Number
        foreach($MemberNumberToAdd in $MemberNumbersToAdd){
            $MemberToAdd = $this.QueryPossibleValuesByNumber($MemberNumberToAdd)
            if($MemberToAdd){
                $Value.Add($MemberToAdd)
            }else{
                # Invalid option warn and continue
                continue
            }
            
        }
        $CurrentValue = Copy-Object $this.GetObjectValue("Members")
        $Comparison = (Compare-Object -ReferenceObject $Value -DifferenceObject $CurrentValue.selected -Property 'Id')
        # If different, change the "Current Value" to the new value
        if($Comparison.count -gt 0){
            $CurrentValue.selected = $Value
        }

        # Return members and the comparison
        return @{ 'Members' = $CurrentValue; 'Comparison' = $Comparison}
    }

    # Stage an update on this object
    [void] Update([Array] $PropertyValues, $Value){
        ([Entity]$this).Update($PropertyValues, $Value,
            ("Group Membership for '{0}' has been updated." -f $this.GetName()),
            ("Failed to update Group Membership for: '{0}'." -f $this.GetName())
        )
    }

    # Functions used to convert CSV information for updates
    [array] GetUpdatePayloads( $PropertyPath, $Values ){
        $payloads = ,$Values
        if($PropertyPath -eq 'Members'){
            $payloads = [Collections.ArrayList] @()
            $MembershipInfo = $this.GetDirtyProperties($PropertyPath)
            $comparison = Compare-Object -ReferenceObject $Values.selected -DifferenceObject $MembershipInfo.OldValue.selected -Property 'Id'
            $MemberIdsToDelete = $comparison | Where-Object {$_.SideIndicator -eq '=>'} | Select-Object -ExpandProperty 'Id'
            $MemberIdsToAdd = $this.DirtyProperties.Members.NewValue.selected | Where-Object {$_.Id -in ($comparison | Where-Object {$_.SideIndicator -eq '<='} | Select-Object -ExpandProperty 'Id')} | Select-Object -ExpandProperty 'Id'

            if($MemberIdsToDelete){
                $payloads += @{'Delete' = @{"Ids" = @($MemberIdsToDelete); "IsAllSelected" = $false; "Search" = ""}}
            }
            if($MemberIdsToAdd){
                $payloads += @{'Add' = @{"Ids" = @($MemberIdsToAdd); "IsAllSelected" = $false; "Search" = ""}}
            }
        }

        return ([Entity]$this).GetUpdatePayloads($PropertyPath, $payloads)
    }
}
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
        #if($null -eq $this.Members.selected){
        #    $this.Members = @{}
        #}
        <#if( $null -eq $this.Members.selected ){
            $this.Members.selected = $this.QueryAllMembers()
            # Update actual object
            $this.object.Members.selected = $this.Members.selected
        }
        return $this.Members.selected#>
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

   #[void] CommitStagedUpdates(){
    #    if ( $PSCmdlet.ShouldProcess($this.GetIdentifier(), 'CommitStagedUpdates') ){
            
   #     }
    #}
    # Override Entity Save since group doesn't yet support staged updates
    # Saves the current entity via the api
    <#[void] Save($SuccessMessage, $FailMessage)
    {
        #$this.CommitStagedUpdates()
        if ( $PSCmdlet.ShouldProcess($this.GetIdentifier(), 'Save') ){
            try{
                $this._endpoint.Save( $this ) | Out-Null
                Write-PSFMessage -Level Output -Message ($SuccessMessage)
            }catch{
                Write-PSFMessage -Level Critical -Message ($FailMessage)
            }
        }
    }#>


    [void] Update($PropertyPath, $CSVValue){
        $this.Update($PropertyPath, $CSVValue,
            "Group '{0}' has been updated." -f $this.GetIdentifier(),
            "Failed to update Group: '{0}'" -f $this.GetIdentifier()
        )
    }

    # Stage an update on this object
    [void] StageUpdate([Array] $PropertyValues, $Value){
        # If PropertyValues is @('Members')
        if($null -eq (Compare-Object $PropertyValues @('Members'))){
            # Return any numbers that shoudl be added
            $MembersToAdd = $Value | Where-Object { $_.Number -NotIn ($this.GetMembersSelected()).Number._value}
            
            # Convert the numbers into a list of IDs
            $MembersToAdd = $MembersToAdd | ForEach-Object { $this.QueryPossibleValuesByNumber($_.Number) } | Select-Object -ExpandProperty Id

            $MembersToDelete = $this.GetMembersSelected() | Where-Object {$_.Number._value -NotIn $Value.Number} | Select-Object -ExpandProperty Id
            $Value = [Collections.ArrayList] @()
            if($MembersToAdd){
                $Value += @{'Add' = @{"Ids" = @($MembersToAdd); "IsAllSelected" = $false; "Search" = ""}}
            }
            if($MembersToDelete){
                $Value += @{'Delete' = @{"Ids" = @($MembersToDelete); "IsAllSelected" = $false; "Search" = ""}}
            }
            if($Value.count -eq 0){
                return
            }
        }
        ([Entity]$this).StageUpdate($PropertyValues, $Value)

 #       $value = @{'PropertyPath' = $PropertyValues; 'OldValue' = $this.GetObjectValue($PropertyValues); 'NewValue' = $CSVValue}
 #       $this.AddDirtyProperties( ($PropertyValues -join '.') , $value)
 #       $this.SetObjectValue($PropertyValues, $CSVValue)
 #       $this.SetDirty()
    }



}
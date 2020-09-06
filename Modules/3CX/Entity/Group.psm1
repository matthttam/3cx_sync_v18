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
    <#
    SetPossibleValueLookup([Array] $PossibleValues)
    {
        foreach($PossibleValue in $PossibleValues){
            $this.PossibleValueLookup[$PossibleValue.Number._value] = $PossibleValue
        }
    }

    [PSObject] GetPossibleValues()
    {
        return $this.Members.possibleValues
    }

    [PSObject] GetSelected()
    {
        return $this.Members.selected
    }

    #[PSObject] GetPossibleValueByNumber([string]$Number){
    #    return $this.PossibleValueLookup[$Number]
    #}
    #>

}
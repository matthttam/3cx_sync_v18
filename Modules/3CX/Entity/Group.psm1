Using module .\Entity.psm1
Using module ..\Endpoints\GroupListEndpoint.psm1

Class Group : Entity
{
    [GroupListEndpoint] $_endpoint
    [Hashtable] $PossibleValueLookup = @{}

    Group($object, $endpoint) : base($object, $endpoint)
    {
        if($this.GetPossibleValues()){
            $this.SetPossibleValueLookup($this.GetPossibleValues())
        }
    }

    SetPossibleValueLookup([Array] $PossibleValues){
        foreach($PossibleValue in $PossibleValues){
            $this.PossibleValueLookup[$PossibleValue.Number._value] = $PossibleValue
        }
    }
    [PSObject] GetPossibleValues()
    {
        return $this.object.Members.possibleValues
    }

    [PSObject] GetSelected()
    {
        return $this.object.Members.selected
    }

    [PSObject] GetPossibleValueByNumber($Number){
        return $this.PossibleValueLookup[$Number]
    }

    [PSObject] GetUpdatePayload($GroupId, [Array] $Selected)
    {
        return @{}
    }
}
Using module .\Entity.psm1
Using module ..\Endpoints\HotdeskingListEndpoint.psm1

Class Hotdesking : Entity
{
    [HotdeskingListEndpoint] $_endpoint
    [Hashtable] $PossibleValueLookup = @{}
    [String] $MacAddress
    [String] $Model
    Hotdesking($object, $endpoint) : base($object, $endpoint)
    {
        $this.MacAddress = $object.ActiveObject.PhoneDevices._value.MacAddress._value;
        $this.Model = $object.ActiveObject.PhoneDevices._value.Model._value;
    }

    [string] GetName(){
        return $this.object.FirstName._value
    }

}
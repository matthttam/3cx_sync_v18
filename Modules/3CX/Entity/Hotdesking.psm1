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

    [String] GetSaveMessage([boolean] $success = $true)
    {
        if($success){
            $message = ("Hotdesk {0} has been saved." -f $this.GetNumber())
        }else{
            $message = ("Failed to save Hotdesk: '{0}'" -f $this.GetNumber())
        }
        
        return $message
    }

}
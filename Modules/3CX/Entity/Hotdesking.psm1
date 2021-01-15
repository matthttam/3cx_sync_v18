Using module .\Entity.psm1
Using module ..\Endpoints\HotdeskingListEndpoint.psm1

Class Hotdesking : Entity
{
    [HotdeskingListEndpoint] $_endpoint
    [Hashtable] $PossibleValueLookup = @{}
    [String] $MacAddress
    [String] $Model
    [String] $Name

    Hotdesking($object, $endpoint) : base($object, $endpoint)
    {
        $this.SetMacAddress($object.ActiveObject.PhoneDevices._value.MacAddress._value)
        $this.SetModel($object.ActiveObject.PhoneDevices._value.Model._value)
        $this.SetName($object.FirstName._value)
    }

    [string] GetIdentifier(){
        $fields = $($this.GetName(), $this.GetModel(), $this.GetMacAddress(), $this.GetObjectID())
        return ('Hotdesking Name: {0}, Model: {1}, Mac: {2} ObjectID: {3}' -f $fields)
    }

    # Sets/Gets MacAddress
    [void] SetMacAddress($MacAddress){
        $this.MacAddress = $MacAddress
    }
    [string] GetMacAddress(){
        return $this.MacAddress
    }

    # Sets/Gets Model
    [void] SetModel($Model){
        $this.Model = $Model
    }
    [string] GetModel(){
        return $this.Model
    }

     # Sets/Gets Model
    [void] SetName($Name){
        $this.Name = $Name
    }
    [string] GetName(){
        return $this.Name
    }

    [void] Save(){
        $this.Save(
            "Hotdesk '{0}' has been saved." -f $this.GetNumber(),
            "Failed to save Hotdesk: '{0}'" -f $this.GetNumber()
        )
    }

    [void] Update([array] $arguments)
    {
        Write-PSFMessage -Level Error -Message ("Update called on hotdesking entity '{0}'. Update is not yet implemented and cannot be used on a Hotdesk extension." -f $this.MacAddress)
    }

}
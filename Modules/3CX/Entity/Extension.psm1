Using module .\Entity.psm1
Using module ..\Endpoints\ExtensionListEndpoint.psm1

Class Extension : Entity
{
    [ExtensionListEndpoint] $_endpoint
    #[String] $number

    Extension($object, $endpoint) : base($object, $endpoint)
    {
        $this.SetNumber($object.number)
    }

    [string] GetIdentifier(){
        return ('Extension Number: {0}, EditID: {1}' -f $this.GetNumber(), $this.GetEditID())
    }
    # Sets/Gets Number
    # For a non-set object number will be stored in $this.number
    # For a set object number also gets stored in $this.object.number._value
    # SetObjectValue does not modify $this.number so $this.object is preferred
    # Set and Get account for this
    [void] SetNumber($number){
        if($this.object.number._value){
            $this.object.number._value = $number
        }
       #$this.number = $number
    }
    [string] GetNumber(){
        #if($this.object.number._value){
            return $this.object.number._value
       # }
        #return $this.number
    }

    [void] Set(){
        $this.Set(
            "Extension '{0}' has been set." -f $this.GetNumber(),
            "Failed to set Extension: '{0}'" -f $this.GetNumber()
        )
    }
    
    [void] Save(){
        $this.Save(
            "Extension '{0}' has been saved." -f $this.GetNumber(),
            "Failed to save Extension: '{0}'" -f $this.GetNumber()
        )
    }

    [void] Update($PropertyPath, $CSVValue){
        $this.Update($PropertyPath, $CSVValue,
            "Extension '{0}' has been updated." -f $this.GetNumber(),
            "Failed to update Extension: '{0}'" -f $this.GetNumber()
        )
    }

    [boolean] IsDisabled(){
        return $this.object.Disabled -eq $true
    }
    
}
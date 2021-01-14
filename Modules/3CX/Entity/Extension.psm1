Using module .\Entity.psm1
Using module ..\Endpoints\ExtensionListEndpoint.psm1

Class Extension : Entity
{
    [ExtensionListEndpoint] $_endpoint
    [String] $number

    Extension($object, $endpoint) : base($object, $endpoint)
    {
        $this.SetNumber($object.number)
    }
    
    # Sets/Gets Number
    [void] SetNumber($number){
        $this.number = $number
    }
    [string] GetNumber(){
        return $this.number
    }

    [void] Set(){
        $this.Set(
            "Extension '{0}' has been set." -f $this.GetNumber(),
            "Failed to set Extension: '{0}'" -f $this.GetNumber()
        )
    }
    
    [PSObject] Save(){
        return $this.Save(
            "Extension '{0}' has been saved." -f $this.GetNumber(),
            "Failed to save Extension: '{0}'" -f $this.GetNumber()
        )
    }

    [PSObject] Update($PropertyPath, $CSVValue){
        return $this.Save(
            "Extension '{0}' has been updated." -f $this.GetNumber(),
            "Failed to update Extension: '{0}'" -f $this.GetNumber()
        )
    }

    [boolean] IsDisabled(){
        return $this.object.Disabled -eq $true
    }
    
}
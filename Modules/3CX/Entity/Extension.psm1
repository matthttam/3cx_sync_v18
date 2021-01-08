Using module .\Entity.psm1
Using module ..\Endpoints\ExtensionListEndpoint.psm1

Class Extension : Entity
{
    [ExtensionListEndpoint] $_endpoint
    [String] $number
    [string] $id

    Extension($object, $endpoint) : base($object, $endpoint)
    {
        $this.SetNumber($object.number)
        $this.SetID($object.id)
    }
    
    # Sets/Gets Number
    [void] SetNumber($number){
        $this.number = $number
    }
    
    [string] GetNumber(){
        return $this.number
    }

    # Sets/Gets ID
    [void] SetID($id){
        $this.id = $id
    }
    
    [string] GetID(){
        return $this.id
    }

    # Returns the save message
    [String] GetSaveMessage()
    {
        $message = ("Extension {0} has been saved." -f $this.GetNumber())
        return $message
    }

    [String] GetSaveMessage([boolean] $success = $true)
    {
        if($success){
            $message = ("Extension {0} has been saved." -f $this.GetNumber())
        }else{
            $message = ("Failed to save Extension: '{0}'" -f $this.GetNumber())
        }
        
        return $message
    }

    
}
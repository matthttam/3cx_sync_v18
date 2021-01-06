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

    # Saves the current entity via the api
    [PSObject] Save()
    {
        try{
            $response = $this._endpoint.Save( $this )
            Write-PSFMessage -Level Output -Message ($this.GetSaveMessage())
            return $response
        }catch{
            Write-PSFMessage -Level Critical -Message ("Failed to Update Group: '{0}'" -f $this.GetName() )
            return $false
        }
    }
}
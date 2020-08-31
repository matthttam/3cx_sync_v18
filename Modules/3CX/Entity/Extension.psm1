Using module .\Entity.psm1
Using module ..\Endpoints\ExtensionListEndpoint.psm1

Class Extension : Entity
{
    [ExtensionListEndpoint] $_endpoint
   # [String] $number

    Extension($object, $endpoint) : base($object, $endpoint)
    {
        #$this.number = $object.number
    }
    
}
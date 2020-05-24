Using module .\Entity.psm1
Using module ..\Endpoints\ExtensionListEndpoint.psm1

Class Extension : Entity
{
    [ExtensionListEndpoint] $_endpoint

    Extension($object, $endpoint) : base($object, $endpoint)
    {
    }
    
}
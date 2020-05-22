Using module .\Entity.psm1
Using module ..\Endpoints\ExtensionList.psm1

Class Extension : Entity
{
    [ExtensionList] $_endpoint

    Extension($object, $endpoint) : base($object, $endpoint)
    {
    }
    
}
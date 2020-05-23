Using module .\Entity.psm1
Using module ..\Endpoints\GroupListEndpoint.psm1

Class Group : Entity
{
    [GroupListEndpoint] $_endpoint

    Group($object, $endpoint) : base($object, $endpoint)
    {
    }

}
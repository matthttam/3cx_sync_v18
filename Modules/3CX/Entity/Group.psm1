Using module .\Entity.psm1
Using module ..\Endpoints\GroupList.psm1

Class Group : Entity
{
    [GroupList] $_endpoint

    Group($object, $endpoint) : base($object, $endpoint)
    {
    }

}
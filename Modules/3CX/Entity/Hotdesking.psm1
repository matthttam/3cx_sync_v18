Using module .\Entity.psm1
Using module ..\Endpoints\HotdeskingListEndpoint.psm1

Class Hotdesking : Entity
{
    [HotdeskingListEndpoint] $_endpoint
    [Hashtable] $PossibleValueLookup = @{}

    Hotdesking($object, $endpoint) : base($object, $endpoint)
    {
    }

}
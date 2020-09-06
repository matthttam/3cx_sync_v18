Using module ..\Endpoints\Endpoint.psm1
Using module ..\Entity\Entity.psm1

Class EntityFactory
{
    Static [Entity[]] $Entities
    [Endpoint] $_endpoint

    ExtensionFactory([Endpoint] $endpoint)
    {
        $this._endpoint = $endpoint
    }
<#
    #Create an instance of a single entity
    [Entity] makeEntity([PSObject] $object)
    {
        return [Entity]::new($object, $this._endpoint)
    }

    # Create entity objects from an array of extension objects
    [Array] makeEntity([Array] $objects){
        $return = @()
        foreach($object in $objects)
        {
            $return += $this.makeEntity($object)
        }
        return $return
    }

    # Create entity based on specific ID
    [Entity] makeEntity([string] $id)
    {
        $payload = @{"id" = $id}
        $responseObject = $this._endpoint.set($payload)
        return [Entity]::new($responseObject, $this._endpoint)
    }

    # Create entity as new object
    [Entity] makeEntity()
    {
        $responseObject = $this._endpoint.New()
        return [Entity]::new($responseObject, $this._endpoint)
    }
#>
}
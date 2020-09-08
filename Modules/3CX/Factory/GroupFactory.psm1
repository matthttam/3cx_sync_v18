Using module .\EntityFactory.psm1
Using module ..\Endpoints\GroupListEndpoint.psm1
Using module ..\Entity\Group.psm1

Class GroupFactory : EntityFactory
{
    Static [Group[]] $Groups
    [GroupListEndpoint] $_endpoint

    GroupFactory([GroupListEndpoint] $endpoint)
    {
        $this._endpoint = $endpoint
    }

    #Create an instance of a single group
    [Group] makeGroup([PSObject] $object)
    {
        return [Group]::new($object, $this._endpoint)
    }

    # Create group objects from an array of group objects
    [Array] makeGroup([Array] $objects){
        $return = @()
        foreach($object in $objects)
        {
            $return += $this.makeGroup($object)
        }
        return $return
    }

    [Group] makeGroup([int32] $id){ return makeGroup([int64] $id)}
    # Create group based on specific ID
    [Group] makeGroup([int64] $id)
    {
        $payload = @{"id" = $id}
        $responseObject = $this._endpoint.set($payload)
        return [Group]::new($responseObject, $this._endpoint)
    }

    # Create group as new object
    [Group] makeGroup()
    {
        $responseObject = $this._endpoint.New()
        return [Group]::new($responseObject, $this._endpoint)
    }
}
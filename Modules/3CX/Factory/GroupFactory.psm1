Using module ..\APIConnection.psm1
Using module .\EntityFactory.psm1
Using module ..\Endpoints\GroupListEndpoint.psm1
Using module ..\Entity\Group.psm1

Class GroupFactory : EntityFactory
{
    Static [Group[]] $Groups
    [GroupListEndpoint] $_endpoint
    $EndpointName = 'GroupListEndpoint'

    GroupFactory([APIConnection] $Connection) : base( $Connection ){

    }

    # Create a brand new group
    [Group] makeGroup()
    {
        $responseObject = $this._endpoint.New()
        return [Group]::new($responseObject, $this._endpoint)
    }

    # Create group objects from an array of group objects
    [Group[]] makeGroup([Array] $objects){
        $return = @()
        foreach($object in $objects)
        {
            $return += $this.makeGroup($object)
        }
        return $return
    }

    # Make group based off an object
    [Group] makeGroup([PSObject] $object)
    {
        #return $this.makeGroup($object.id)
        return [Group]::new($object, $this._endpoint)
    }

    # If a 32 bit integer is passed convert to 64 bit.
    [Group] makeGroup([int32] $id){ return $this.makeGroup([int64] $id)}
    # Create group based on specific ID
    [Group] makeGroup([int64] $id)
    {
        $payload = @{"id" = [int] $id}
        $responseObject = $this._endpoint.set($payload)
        return [Group]::new($responseObject, $this._endpoint)
    }
    
    # Get all group and return them as an array of groups
    [Group[]] GetGroups()
    {
        $GroupList = $this._endpoint.Get() | Select-Object -ExpandProperty 'list'
        return $this.makeGroup($GroupList)
    }

    # Get groups based on an array of names
    [Group[]] GetGroupsByName([array] $Names){
        $GroupList = $this._endpoint.Get() | Select-Object -ExpandProperty 'list' | Where-Object {$_.Name -in $Names}
        return $this.makeGroup($GroupList)
    }
}
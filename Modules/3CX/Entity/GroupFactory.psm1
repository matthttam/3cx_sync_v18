Using module ..\Endpoints\GroupList.psm1
Using module .\Group.psm1

Class GroupFactory
{
    Static [Group[]] $Extensions
    [GroupList] $_endpoint

    GroupFactory([GroupList] $endpoint)
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

    # Create group based on specific ID
    [Group] makeGroup([string] $id)
    {
        $payload = @{"id" = $id}
        $response = $this._endpoint.set($payload)
        $responseObject = $response.content | ConvertFrom-Json -ErrorAction Stop
        return [Group]::new($responseObject, $this._endpoint)
    }

    # Create group as new object
    [Group] makeGroup()
    {
        $response = $this._endpoint.New()
        $responseObject = $response.content | ConvertFrom-Json -ErrorAction Stop
        return [Group]::new($responseObject, $this._endpoint)
    }
}
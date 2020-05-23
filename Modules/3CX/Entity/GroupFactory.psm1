Using module ..\Endpoints\GroupListEndpoint.psm1
Using module .\Group.psm1

Class GroupFactory
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

    # Create group based on specific ID
    [Group] makeGroup([string] $id)
    {
        $payload = @{"id" = $id}
        $responseObject = $this._endpoint.set($payload)
        #$response = $this._endpoint.set($payload)
        #$responseObject = $response.content | ConvertFrom-Json -ErrorAction Stop
        return [Group]::new($responseObject, $this._endpoint)
    }

    # Create group as new object
    [Group] makeGroup()
    {
        $responseObject = $this._endpoint.New()
        #$response = $this._endpoint.New()
        #$responseObject = $response.content | ConvertFrom-Json -ErrorAction Stop
        return [Group]::new($responseObject, $this._endpoint)
    }
}
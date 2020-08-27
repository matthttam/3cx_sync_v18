Using module ..\Endpoints\HotdeskingListEndpoint.psm1
Using module .\Hotdesking.psm1

Class HotdeskingFactory
{
    Static [Hotdesking[]] $Hotdeskings
    [HotdeskingListEndpoint] $_endpoint

    HotdeskingFactory([HotdeskingListEndpoint] $endpoint)
    {
        $this._endpoint = $endpoint
    }

    #Create an instance of a single Hotdesking
    [Hotdesking] makeHotdesking([PSObject] $object)
    {
        return [Hotdesking]::new($object, $this._endpoint)
    }

    # Create Hotdesking objects from an array of Hotdesking objects
    [Array] makeHotdesking([Array] $objects){
        $return = @()
        foreach($object in $objects)
        {
            $return += $this.makeHotdesking($object)
        }
        return $return
    }

    # Create Hotdesking based on specific ID
    [Hotdesking] makeHotdesking([string] $id)
    {
        $payload = @{"id" = $id}
        $responseObject = $this._endpoint.set($payload)
        return [Hotdesking]::new($responseObject, $this._endpoint)
    }

    # Create Hotdesking as new object
    [Hotdesking] makeHotdesking( [Hashtable] $HotdeskingInfo)
    {
        return $this.makeHotdesking($HotdeskingInfo.MacAddress, $HotdeskingInfo.Model)
    }
    [Hotdesking] makeHotdesking( [String] $mac, [String] $model)
    {
        $responseObject = $this._endpoint.New($mac, $model)
        return [Hotdesking]::new($responseObject, $this._endpoint)
    }
}
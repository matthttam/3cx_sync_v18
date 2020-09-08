Using module .\Mapping.psm1


class HotdeskingMapping : Mapping
{
    # Hashtable HotdeskingMapping CSV Headers to an array of Objects containing API Names
    [hashtable]$ParsedConfig = @{}

    HotdeskingMapping([PSCustomObject] $config) : base($config)
    {
        $this.ParseConfig($config)
    }

    [void] ParseConfig([PSCustomObject] $config)
    {
        $APIPaths = Get-Member -InputObject $config -MemberType Properties | Select-Object -ExpandProperty "Name"
        foreach($APIPath in $APIPaths){
            $this.ParsedConfig.($config.$APIPath) = $APIPath
        }
    }

    # Return 3CX path array based on CSVHeader provided
    [string] GetApiPath($CSVHeader)
    {
        return $this.ParsedConfig.$CSVHeader
    }
    
    [array] GetApiPaths()
    {
        return @($this.config.PSObject.Properties | Select-Object -ExpandProperty 'Name')
    }
    
}
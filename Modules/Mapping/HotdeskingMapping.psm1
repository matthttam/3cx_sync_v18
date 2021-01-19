Using module .\Mapping.psm1


class HotdeskingMapping : Mapping
{
    # Hashtable HotdeskingMapping CSV Headers to an array of Objects containing API Names
    [hashtable]$ParsedConfig = @{}

    HotdeskingMapping([PSCustomObject] $mapping) : base($mapping)
    {
        $this.ParseMapping($mapping)
    }

    [void] ParseMapping([PSCustomObject] $mapping)
    {
        $APIPaths = Get-Member -InputObject $mapping -MemberType Properties | Select-Object -ExpandProperty "Name"
        foreach($APIPath in $APIPaths){
            $this.ParsedConfig.($mapping.$APIPath) = $APIPath
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
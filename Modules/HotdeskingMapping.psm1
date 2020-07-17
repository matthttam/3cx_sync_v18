Using module .\Mapping.psm1


class HotdeskingMapping : Mapping
{
    # Hashtable HotdeskingMapping CSV Headers to an array of Objects containing API Names
    [hashtable]$ParsedConfig = @{}

    HotdeskingMapping([PSCustomObject] $config) : base($config)
    {
        $this.ParseConfig($config)
    }

    <#
    [void] ParseConfig([PSCustomObject] $config)
    {
        $APIPaths = Get-Member -InputObject $config -MemberType Properties | Select-Object -ExpandProperty "Name"
        foreach($Path in $APIPaths){
            $PropertyPath = @()
            foreach($PathName in ($Path -split '\.')){
                $PropertyPath = $PropertyPath + @{"Name"=$PathName}
            }
            $CSVHeader = $config.$Path
            $this.ParsedConfig.$CSVHeader = $PropertyPath
        }
    }
    #>

    [void] ParseConfig([PSCustomObject] $config)
    {
        $APIPaths = Get-Member -InputObject $config -MemberType Properties | Select-Object -ExpandProperty "Name"
        #foreach($Path in $APIPaths){
        foreach($APIPath in $APIPaths){
            <#
            $PropertyPath = @()
            foreach($PathName in ($Path -split '\.')){
                $PropertyPath = $PropertyPath + @{"Name"=$PathName}
            }#>
            #$CSVHeader = $config.$Path
            $this.ParsedConfig.($config.$APIPath) = $APIPath
        }
    }
    <#
    
    [PSCustomObject] GetParsedConfig($CSVHeaderValue)
    {
        return $this.ParsedConfig.$CSVHeaderValue
    }

    [array] GetParsedConfigValues($CSVHeaderValue)
    {
        return @($this.GetParsedConfig($CSVHeaderValue).values)
    }

    [array] GetConfigPathKeys()
    {
        return @($this.config.PSObject.Properties | Select-Object -ExpandProperty 'Name')
    }

    [array] GetConfigCSVKeys()
    {
        return @($this.config.PSObject.Properties | Select-Object -ExpandProperty 'Value')
    }
    #>

    # Return 3CX path array based on CSVHeader provided
    [string] GetApiPath($CSVHeader)
    {
        return $this.ParsedConfig.$CSVHeader
    }

    <#
    [array] GetApiPaths()
    {
        return $this.ParsedConfig.Values
    }
    #>
    
    [array] GetApiPaths()
    {
        return @($this.config.PSObject.Properties | Select-Object -ExpandProperty 'Name')
    }
    
}
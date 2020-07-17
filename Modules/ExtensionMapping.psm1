Using module .\Mapping.psm1


class ExtensionMapping : Mapping
{
    # Hashtable ExtensionMapping CSV Headers to  #an array of Objects containing API Names
    [hashtable]$ParsedConfig = @{}

    ExtensionMapping([PSCustomObject] $config) : base($config)
    {
        $this.ParseConfig($config)
    }

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

}
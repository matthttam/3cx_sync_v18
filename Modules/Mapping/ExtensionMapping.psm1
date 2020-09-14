Using module .\Mapping.psm1

class ExtensionMapping : Mapping
{

    [hashtable]$ParsedMapping = @{}

    ExtensionMapping([PSCustomObject] $mapping) : base($mapping)
    {
        $this.SetParsedMapping($this.ParseMapping($mapping))
    }

    [hashtable] ParseMapping([PSCustomObject] $mapping)
    {
        $return = [hashtable] @{}
        $APIPaths = Get-Member -InputObject $mapping -MemberType Properties | Select-Object -ExpandProperty "Name"
        foreach($Path in $APIPaths){
            $PropertyPath = @()
            foreach($PathName in ($Path -split '\.')){
                $PropertyPath = $PropertyPath + @{"Name"=$PathName}
            }
            $CSVHeader = $mapping.$Path
            $return.$CSVHeader = $PropertyPath
        }
        return $return
    }
    
    [void] SetParsedMapping($Mapping){
        $this.ParsedMapping= $Mapping
    }
    [hashtable] GetParsedMapping(){
        return $this.ParsedMapping
    }


    [PSCustomObject] GetParsedMappingKey($CSVHeaderValue)
    {
        return $this.ParsedMapping.$CSVHeaderValue
    }

    [array] GetParsedMappingValues($CSVHeaderValue)
    {
        return @($this.GetParsedMappingKey($CSVHeaderValue).values)
    }

    [array] GetMappingPathKeys()
    {
        return @($this.mapping.PSObject.Properties | Select-Object -ExpandProperty 'Name')
    }

    [array] GetMappingCSVKeys()
    {
        return @($this.mapping.PSObject.Properties | Select-Object -ExpandProperty 'Value')
    }

}
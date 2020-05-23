Using module .\Config.psm1

class Mapping
{
    # Hashtable mapping CSV Headers to an array of Objects containing API Names
    [hashtable]$ParsedConfig = @{}
    [PSCustomObject] $config

    Mapping([PSCustomObject] $config)
    {
        $this.config = $config
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

    [PSObject] ConvertToType( $Value, $attributeInfo )
    {
        if($attributeInfo.Type-eq 'String'){
            return $Value
        }elseif($attributeInfo.Type -eq 'Enum'){
            return $attributeInfo.possibleValues[$Value]
        }elseif($attributeInfo.Type -eq 'SelectedItem'){
            return $attributeInfo.possibleValues | Where-Object Id -eq $Value
        }elseif($attributeInfo.Type -eq 'Boolean'){
            if($Value -eq '1' -or $Value -eq 'true'){
                return $true
            }else{
                return $false
            }
        }elseif($attributeInfo.Type -eq 'Collection'){
            throw 'Unsupported api mapping type'
        }elseif($attributeInfo.Type -eq 'File'){
            throw 'Unsupported api mapping type'
        }elseif($attributeInfo.Type -eq 'Item'){
            throw 'Unsupported api mapping type'
        }elseif($attributeInfo.Type -eq 'ItemSet'){
            throw 'Unsupported api mapping'
        }elseif($attributeInfo.Type -eq 'TimeRanges'){
            throw 'Unsupported api mapping type'
        }else{
            return ""
        }
    }
}
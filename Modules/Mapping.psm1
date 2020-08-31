Using module .\Config.psm1
Using module .\3CX\Type.psm1

class Mapping
{
    # Hashtable mapping CSV Headers to an array of Objects containing API Names
    [hashtable]$ParsedConfig = @{}
    [PSCustomObject] $config

    Mapping([PSCustomObject] $config)
    {
        $this.config = $config
    }
    
    #??? I'm so confused by this function actually
    [PSCustomObject] GetParsedConfig($CSVHeaderValue) #Deprecated
    {
        return $this.ParsedConfig.$CSVHeaderValue
    }

    [array] GetParsedConfigValues($CSVHeaderValue) #Deprecated
    {
        return @($this.GetParsedConfig($CSVHeaderValue).values)
    }

    [array] GetConfigPathKeys() #Deprecated
    {
        return @($this.config.PSObject.Properties | Select-Object -ExpandProperty 'Name')
    }

    [array] GetCSVHeaders(){
        return @($this.config.PSObject.Properties | Select-Object -ExpandProperty 'Value')
    }
    [array] GetConfigCSVKeys() #Deprecated
    {
        return @($this.config.PSObject.Properties | Select-Object -ExpandProperty 'Value')
    }

    [PSObject] ConvertToType( $Value, $attributeInfo )
    {
        
        if($attributeInfo.Type -eq [Type]::String  ){ 
            return $Value
        }elseif($attributeInfo.Type -eq [Type]::Enum ){ 
            return $attributeInfo.possibleValues[$Value]
        }elseif($attributeInfo.Type -eq [Type]::SelectedItem ){ 
            return $attributeInfo.possibleValues | Where-Object Id -eq $Value
        }elseif($attributeInfo.Type -eq [Type]::Boolean ){ 
            if($Value -eq '1' -or $Value -eq 'true'){
                return $true
            }else{
                return $false
            }
        }elseif($attributeInfo.Type -eq [Type]::Collection ){ 
            throw 'Unsupported api mapping type'
        }elseif($attributeInfo.Type -eq [Type]::File ){ 
            throw 'Unsupported api mapping type'
        }elseif($attributeInfo.Type -eq [Type]::Item ){ 
            throw 'Unsupported api mapping type'
        }elseif($attributeInfo.Type -eq [Type]::ItemSet ){ 
            throw 'Unsupported api mapping'
        }elseif($attributeInfo.Type -eq [Type]::TimeRanges ){ 
            throw 'Unsupported api mapping type'
        }else{
            throw 'Unsupported api mapping type'
        }
    }

    # Return the CSV associated with the string APIPath
    [String] ExtractValueByAPIPath( [String] $ApiPath, [PSCustomObject] $row )
    {
        $CSVHeader = $this.GetCSVHeader( $ApiPath )
        return $this.ExtractValueByCSVHeader( $CSVHeader, $row )
    }
    [String] ExtractValueByCSVHeader( [String] $CSVHeader, [PSCustomObject]  $row )
    {
        return $row.$CSVHeader;
        #$ApiPath = $this.GetAPIPath($CSVHeader);
        #return $this.ExtractValueByAPIPath( $ApiPath, $row )
    }

    [String] GetCSVHeader( $ApiPath )
    {
        return $this.config.$ApiPath;
    }


}
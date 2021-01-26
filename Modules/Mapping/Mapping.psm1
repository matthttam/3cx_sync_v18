Using module ..\Config\Config.psm1
Using module ..\3CX\ValueType.psm1

class Mapping
{
    # Hashtable mapping CSV Headers to an array of Objects containing API Names
    [Hashtable] $Mapping
    

    Mapping([Hashtable] $mapping)
    {
        $this.SetMapping($mapping)
    }

    # Sets/Gets mapping object
    [void] SetMapping($mapping){
        $this.mapping = $mapping
    }
    [PSCustomObject] GetMapping(){
        return $this.mapping
    }

    # Return the CSV value associated with the string APIPath
    [String] ExtractValueByAPIPath( [String] $ApiPath, [PSCustomObject] $row )
    {
        $CSVHeader = $this.GetCSVHeaderByAPIPath( $ApiPath )
        return $row.$CSVHeader;
    }

    # Get CSV Header based on API Mapping
    [String] GetCSVHeaderByAPIPath( $ApiPath )
    {
        return $this.mapping.$ApiPath
    }

    [String] GetAPIPathByCSVHeader( $CSVHeader ){
        return $this.mapping.getEnumerator() | Where-Object {$_.Value -eq "$CSVHeader"} | Select-Object -ExpandProperty 'Name'
    }

    [array] GetAPIPaths()
    {
        return $this.mapping.keys
    }

    [array] GetCSVHeaders()
    {
        return $this.mapping.values
    }

    # Convert a value to the type specified from an attributeInfo
    [PSObject] ConvertToType( $Value, $attributeInfo )
    {
        if($attributeInfo.Type -eq [ValueType]::String  ){ 
            return $Value
        }elseif($attributeInfo.Type -eq [ValueType]::Enum ){ 
            if($Value -in $attributeInfo.possibleValues){
                return $Value
            }else{
                return $attributeInfo.possibleValues[$Value]
            }
            throw 'possible value listing for enum not supported'
        }elseif($attributeInfo.Type -eq [ValueType]::SelectedItem ){ 
            return $attributeInfo.possibleValues | Where-Object Id -eq $Value
        }elseif($attributeInfo.Type -eq [ValueType]::Boolean ){ 
            if($Value -eq '1' -or $Value -eq 'true'){
                return $true
            }else{
                return $false
            }
        }elseif($attributeInfo.Type -eq [ValueType]::Collection ){ 
            throw 'Unsupported api mapping type Collection (12)'
        }elseif($attributeInfo.Type -eq [ValueType]::File ){ 
            throw 'Unsupported api mapping type File (14)'
        }elseif($attributeInfo.Type -eq [ValueType]::Item ){ 
            #throw 'Unsupported api mapping type Item (9)'
            return [string] $Value
        }elseif($attributeInfo.Type -eq [ValueType]::ItemSet ){ 
            throw 'Unsupported api mappingtype ItemSet (13)'
        }elseif($attributeInfo.Type -eq [ValueType]::TimeRanges ){ 
            throw 'Unsupported api mapping type TimeRanges (6)'
        }else{
            throw 'Unsupported api mapping type Unknown'
        }
    }

}
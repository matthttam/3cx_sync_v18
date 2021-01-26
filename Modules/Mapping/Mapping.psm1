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

    <#
    # Default parse mapping function which expands each name from a New/Update mapping
    # and splits them by the period to build a property path that 3CX would understand
    # The key for each of these is the CSV header of the mapped field
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
            #$return.($this.GetCSVHeader($mapping.$Path)) = $PropertyPath
        }
        return $return
    }
    
    [void] SetParsedMapping($Mapping){
        $this.ParsedMapping = $Mapping
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
        return @($this.Mapping.PSObject.Properties | Select-Object -ExpandProperty 'Name')
    }

    [array] GetMappingCSVKeys()
    {
        return @($this.Mapping.PSObject.Properties | Select-Object -ExpandProperty 'Value')
    }
    #>
}
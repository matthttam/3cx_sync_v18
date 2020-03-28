Using module .\Config.psm1

class Mapping : Config
{
    [hashtable]$ParsedConfig = @{}
    Mapping([string]$a) : base($a)
    {
        $this.ParseConfig($this.Config)
    }

    [void] ParseConfig([PSCustomObject] $config)
    {
        # NOT DONE YET
        $APIPaths = Get-Member -InputObject $this.config -MemberType Properties | Select-Object -ExpandProperty "Name"
        foreach($Path in $APIPaths){
            # CSV Header: $this.Config.$Path
            $PropertyPath = @()
            foreach($PathName in ($Path -split '\.')){
                $PropertyPath = $PropertyPath + @{"Name"=$PathName}
            }
            $CSVHeader = $this.Config.$Path
            $this.ParsedConfig.$CSVHeader = $PropertyPath
            <#$this.ParsedConfig = $this.ParsedConfig + @{
                "PropertyPath" = $PropertyPath
                "PropertyValueHeader" = $this.Config.$Path
            }#>
            #$blah = @{
            #    "PropertyPath" = @()
            #}
        }
    }

    [hashtable] GetUpdatePayload( $Extension, [string] $CSVHeader, $CSVData){        
            $attributeInfo = GetValue -object $Extension.ActiveObject -key $this.ParsedConfig.$CSVHeader.Values
            
            if($attributeInfo.type -eq 'String'){
                $Data = $CSVData
            }elseif($attributeInfo.Type -eq 'Enum'){
                $Data = $attributeInfo.possibleValues[$CSVData]
            }elseif($attributeInfo.Type -eq 'SelectedItem'){
                $Data = $attributeInfo.possibleValues | Where-Object Id -eq $CSVData
            }elseif($attributeInfo.Type -eq 'Boolean'){
                if($CSVData -eq '1'){
                    $Data = $true
                }else{
                    $Data = $false
                }
            }elseif($attributeInfo.Type -eq 'Collection'){
                throw 'Unsupported api mapping'
            }elseif($attributeInfo.Type -eq 'File'){
                throw 'Unsupported api mapping'
            }elseif($attributeInfo.Type -eq 'Item'){
                throw 'Unsupported api mapping'
            }elseif($attributeInfo.Type -eq 'ItemSet'){
                throw 'Unsupported api mapping'
            }elseif($attributeInfo.Type -eq 'TimeRanges'){
                throw 'Unsupported api mapping'
            }else{
                $Data = ""
            }

            $payload = @{
                "Path" = @{
                    "ObjectId" = $Extension.Id
                    "PropertyPath" = $this.ParsedConfig.$CSVHeader
                }
                "PropertyValue" = $Data
            }
            return $payload
    }
    
}

function GetValue()
{
    param(
        [Parameter(Mandatory=$true)] $object,
        [Parameter(Mandatory=$true)] $key
    )
    if( $key -is [string] ){
        $p1,$p2 = $key.Split(".")
    }elseif( $key -is [array] ){
        $p1, $p2 = $array
    }else{
        return $false
    }
    if($p2) { return GetValue -object $object.$p1 -key $p2 }
    else { return $object.$p1 }
}
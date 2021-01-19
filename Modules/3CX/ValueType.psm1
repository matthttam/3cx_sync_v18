class ValueType {
    static [string] $String = 3
    static [string] $Enum = 11
    static [string] $SelectedItem = 10
    static [string] $Boolean = 0
    static [string] $Collection = 12
    static [string] $File = 14
    static [string] $Item = 9 #13?
    static [string] $ItemSet = 13 #9?
    static [string] $TimeRanges = 6
    static [string] $Object = 20 #Not really sure what to call this
    ValueType([PSCustomObject] $config)
    {
        
    }
}
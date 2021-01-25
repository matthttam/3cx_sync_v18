Using module .\Mapping.psm1

class GroupMapping : Mapping
{

    [hashtable]$ParsedMapping = @{}

    GroupMapping([PSCustomObject] $mapping) : base($mapping)
    {
        #$this.SetParsedMapping($this.ParseMapping($mapping))
    }

}
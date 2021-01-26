Using module .\Mapping.psm1

class ExtensionMapping : Mapping
{

    [hashtable]$ParsedMapping = @{}

    ExtensionMapping([PSCustomObject] $mapping) : base($mapping)
    {
        #$this.SetParsedMapping($this.ParseMapping($mapping))
    }

}
Using module .\Config.psm1
Using module ..\Mapping\HotdeskingMapping.psm1

class HotdeskingConfig : Config
{
    # Name of Node From Config File to Store
    [string] $ConfigNode = 'Hotdesking'
    [hashtable] $Mapping = @{}
    [array] $RequiredFields = @()

    HotdeskingConfig( [string] $FullPath ) : base($FullPath){
         # Extract New and Update Hotdesking Mappings
        $this.Mapping.New = [HotdeskingMapping]::New($this.Config.New)
        $this.Mapping.Update = [HotdeskingMapping]::New($this.Config.Update)
    }

}
Using module .\Config.psm1
Using module ..\Mapping\GroupMapping.psm1

class GroupConfig : Config
{
    # Name of Node From Config File to Store
    [string] $ConfigNode = 'Group'
    [hashtable] $Mapping = @{}
    [hashtable] $Threshold = @{ "Add" = $false; "Delete" = $false}
    [string] $Key
    [array] $RequiredFields = @('key', 'threshold')
    
    GroupConfig( [string] $FullPath ) : base($FullPath){
        # Store Threshold Values
        if($this.config.Threshold.Add){
            $this.SetThreshold("Add", $this.config.Threshold.Add)
        }
        if($this.config.Threshold.Delete){
            $this.SetThreshold("Delete", $this.config.Threshold.Delete)
        }

        # Create Mappings for New and Update
        $this.Mapping.New = [GroupMapping]::new($this.config.New)
        $this.Mapping.Update = [GroupMapping]::new($this.config.Update)

        # Set Key
        $this.SetKey($this.config.Key)
    }

    # Sets/Gets Key Settings
    [void] SetKey([string] $Key)
    {
        $this.Key = $Key
    }
    [string] GetKey()
    {
        return $this.Key
    }

}
Using module .\Config.psm1
Using module ..\Mapping\ExtensionMapping.psm1

class ExtensionConfig : Config
{
    # Name of Node From Config File to Store
    [string] $ConfigNode = 'Extension'
    [hashtable] $Mapping = @{}
    [hashtable] $Threshold = @{ "Add" = $false; "Remove" = $false}
    [string] $Key
    [array] $RequiredFields = @('key', 'threshold')
    
    ExtensionConfig( [string] $FullPath ) : base($FullPath){
        # Store Threshold Values
        if($this.config.Threshold.Add){
            $this.SetThreshold("Add", $this.config.Threshold.Add)
        }
        if($this.config.Threshold.Remove){
            $this.SetThreshold("Remove", $this.config.Threshold.Remove)
        }

        # Create Mappings for New and Update
        $this.Mapping.New = [ExtensionMapping]::new($this.config.New)
        $this.Mapping.Update = [ExtensionMapping]::new($this.config.Update)

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
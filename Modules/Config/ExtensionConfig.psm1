Using module .\Config.psm1
Using module ..\Mapping\ExtensionMapping.psm1

class ExtensionConfig : Config
{
    # Name of Node From Config File to Store
    [string] $ConfigNode = 'Extension'
    [hashtable] $Mapping = @{}
    [hashtable] $Threshold = @{ "Add" = $false; "Disable" = $false}
    [string] $Key
    [array] $RequiredFields = @('key', 'threshold')
    
    ExtensionConfig( [string] $FullPath ) : base($FullPath){
        # Set Key
        $this.SetKey($this.Config.Key)

        # Store Threshold Values
        if($this.config.Threshold.Add){
            $this.SetThreshold("Add", $this.Config.Threshold.Add)
        }
        if($this.config.Threshold.Disable){
            $this.SetThreshold("Disable", $this.Config.Threshold.Disable)
        }

        # Set Number and key in the New Mapping config if not set
        if( -not $this.Config.New['Number']){
            $this.Config.New['Number'] = $this.GetKey()
        }

        # Create Mappings for New and Update
        $this.Mapping.New = [ExtensionMapping]::new($this.Config.New)
        $this.Mapping.Update = [ExtensionMapping]::new($this.Config.Update)
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
Using module .\Config.psm1
Using module ..\Mapping\ExtensionMapping.psm1

class ExtensionConfig : Config
{
    # Name of Node From Config File to Store
    [string] $ConfigNode = 'Extension'
    [hashtable] $Mapping = @{}
    [hashtable] $Threshold = @{ "Add" = "0"; "Remove" = "0"}
    [string] $Key
    [array] $RequiredFields = @('key', 'threshold')
    

    ExtensionConfig( [string] $FullPath ) : base($FullPath){
        # Store Threshold Values
        $this.SetThreshold("Add", $this.config.Threshold.Add)
        $this.SetThreshold("Remove", $this.config.Threshold.Remove)

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

    # Sets/Gets Threshold Settings
    [void] SetThreshold($name, $value)
    {
        $this.Threshold.$name = $value
    }
    [decimal] GetThreshold([string] $name)
    {
        if($this.HasThreshold($name) -eq $false){
            return $null
        }else{
            return ($this.Threshold.$name).TrimEnd( '%', ' ') # Remove extra percent and spaces at end
        }
    }

    #Return boolean weather or not the percentage of modified extensions out of all active extensions exceeds the set threshold
    [boolean] IsOverThreshold( [string] $name, $CountOfModified, $CountOfActiveExtensions)
    {
        $Percentage = [Math]::Round( ($CountOfModified / $CountOfActiveExtensions * 100),2)
        if( $Percentage -ge $this.GetThreshold($name) ){
            return $true
        }
        return $false
    }

    [boolean] HasThreshold([string] $name){
        if($name -eq '' -or -not $this.Threshold.$name -or $this.Threshold.$name -eq $false){
            return $false
        }
        return $true
    }

}
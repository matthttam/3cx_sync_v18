class Config
{
    [string]$FullPath
    [string]$Path
    [string]$Filename
    [PSCustomObject]$Config
    [string] $ConfigNode = $null
    [array] $RequiredFields = $null
    [string] $CSVPath
    [hashtable] $Threshold = @{}

    Config( [string] $FullPath )
    {
        $this.SetFullPath($FullPath)
        $this.SetPath($FullPath)
        $this.SetFileName($FullPath)
        
        # Verify File Exists
        $this.VerifyFileExists($FullPath)
        $this.SetConfig($FullPath)
        
        if($this.GetRequiredFields()){
            $this.VerifyRequiredFields($this.GetRequiredFields())
        }
        
        # Set CSV Path
        if( $this.config.CSVPath){
            $this.SetCSVPath($this.config.CSVPath)
        }
    }

    # Sets/Gets ConfigNode
    [void] SetConfigNode([array] $ConfigNode){
        $this.ConfigNode = $ConfigNode
    }

    [array] GetConfigNode()
    {
        return $this.ConfigNode
    }

    # Sets/Gets RequiredFields Array
    [void] SetRequiredFields([array] $RequiredFields){
        $this.RequiredFields = $RequiredFields
    }

    [array] GetRequiredFields()
    {
        return $this.RequiredFields
    }

    # Sets/Gets Config of Config Data
    [void] SetConfig([string] $FullPath){
        $JsonFile = (Get-Content -Path $FullPath) | ConvertFrom-Json -Depth 10 -ErrorAction Stop -AsHashtable
        if($this.ConfigNode){
            $this.Config = $JsonFile.($this.ConfigNode)
        }else{
            $this.Config = $JsonFile
        }
    }

    [string] GetConfig()
    {
        return $this.Config
    }

    # Sets/Gets Filename of Config File
    [void] SetFullPath([string] $FullPath){
        $this.FullPath = $FullPath
    }

    [string] GetFullPath()
    {
        return $this.FullPath
    }

    # Sets/Gets Path where Config File resides
    [void] SetPath([string] $FullPath){
        $this.Path = Split-Path $FullPath
    }

    [string] GetPath()
    {
        return $this.Path
    }

    # Sets/Gets Filename of ConfigF File
    [void] SetFilename([string] $FullPath){
        $this.Filename = Split-Path $FullPath -Leaf
    }

    [string] GetFilename()
    {
        return $this.Filename
    }

    # Verify File Exists
    [void] VerifyFileExists($FullPath)
    {
        if(-not (Test-Path $FullPath))
        {
            throw [System.IO.FileNotFoundException]::new("Could not find Config file: $FullPath", $FullPath)
        }else{
            Write-Verbose ('Config file {0} found' -f $FullPath)
        }
    }

    [void] VerifyRequiredFields( [array]$RequiredFields )
    {
        $MissingProperties = $RequiredFields | Where-Object {$this.config.keys -NOTcontains $_}
        
        if($MissingProperties){
            throw [System.Configuration.ConfigurationException]::new('Config file "{0}" located at "{2}" missing required settings: {3}' -f ($this.GetFilename(), $this.GetPath(), ($MissingProperties -join ', ')))
        }else{
            Write-Verbose('Verification of the required fields of {0} successful.' -f $this.Filename)
        }
    }

    # Sets/Gets CSVPath Settings
    [void] SetCSVPath([string] $CSVPath)
    {
        $this.CSVPath = $CSVPath
    }
    [string] GetCSVPath()
    {
        return $this.CSVPath
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
    [boolean] IsOverThreshold( [string] $name, $CountOfModified, $TotalCount)
    {
        $Percentage = [Math]::Round( ($CountOfModified / $TotalCount * 100),2)
        if( $Percentage -ge $this.GetThreshold($name) ){
            return $true
        }
        return $false
    }

    # Return if a specific threshold is in this config
    [boolean] HasThreshold([string] $name){
        if($name -eq '' -or -not $this.Threshold.$name -or $this.Threshold.$name -eq $false){
            return $false
        }
        return $true
    }

    # Apply Thresholds to a list of objects
    [void] ApplyThresholds($Name, $ObjectsToChange, $TotalCount, $ExceededMessage, $CanceledMessage){
        # Are we removing any extensions?
        if($this.HasThreshold($Name) -and $ObjectsToChange.length -gt 0){
            # Are we exceeding our threshold?
            if($this.IsOverThreshold($Name, $ObjectsToChange.length, $TotalCount)){
                Write-PSFMessage -Level Critical -Message ($ExceededMessage)
                # Reset each extension that would have been disabled
                foreach($Object in $ObjectsToChange){
                    Write-PSFMessage -Level Critical -Message ($CanceledMessage -f $Object.GetIdentifier())
                    $Object.Cancel()
                }
            }
        }
    }
}
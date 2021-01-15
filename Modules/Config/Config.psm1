class Config
{
    [string]$FullPath
    [string]$Path
    [string]$Filename
    [PSCustomObject]$Config
    [string] $ConfigNode = $null
    [array] $RequiredFields = $null
    [string] $CSVPath

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
        $JsonFile = (Get-Content -Path $FullPath) | ConvertFrom-Json -Depth 10 -ErrorAction Stop
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
        $ConfigProperties = Get-Member -InputObject $this.config -MemberType Properties | Select-Object -ExpandProperty "Name"
        $ComparisonDifference = Compare-Object -ReferenceObject $ConfigProperties -DifferenceObject $RequiredFields
        $MissingProperties = $ComparisonDifference | Where-Object sideIndicator -eq '=>' | Select-Object -ExpandProperty 'InputObject'
        
        $NodeMessage = ""
        if($this.GetConfigNode()){
            $NodeMessage = ' node "{0}" ' -f $this.GetConfigNode()
        }
        if($MissingProperties){
            throw [System.Configuration.ConfigurationException]::new('Config file "{0}" {1} located in "{2}" missing required settings: {3}' -f ($this.GetFilename(), $this.GetPath(), $NodeMessage, ($MissingProperties -join ', ')))
        }else{
            Write-Verbose('Verification of Required Fields of {0} {1} successful' -f $this.Filename, $NodeMessage)
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
}
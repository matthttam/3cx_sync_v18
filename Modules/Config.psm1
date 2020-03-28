class Config
{
    [string]$FullPath
    [string]$Path
    [string]$Filename
    [PSCustomObject]$Config
    [int]$Format

    static [int]$JSON = 1
    static [int]$CSV = 2

    # Hidden helper methods to help with chaining constructors
    hidden Init([string]$FullPath)  {$this.Init($FullPath, $this::JSON)}
    hidden Init([string]$FullPath, [int]$Format){
        $this.Path = Split-Path $FullPath
        $this.Filename = Split-Path $FullPath -Leaf
        $this.Format = $Format
        # Verify File Exists
        if(-not (Test-Path $FullPath))
        {
            throw [System.IO.FileNotFoundException]::new("Could not find file: $FullPath", $FullPath)
        }else{
            Write-Verbose ('{0} found' -f $FullPath)
        }

        # Read the File
        if($this.Format -eq $this::JSON){
            $this.Config = (Get-Content -Path $FullPath) | ConvertFrom-Json -ErrorAction Stop
        }elseif($this.Format -eq $this::CSV){
            $this.Config = (Get-Content -Path $FullPath) | ConvertFrom-CSV -ErrorAction Stop
        }else{
            $this.Config = (Get-Content -Path $FullPath)
        }
    }

    Config([string]$FullPath)
    {
        $this.Init($FullPath)
    }

    Config([string]$FullPath, [int] $Format)
    {
        $this.Init($FullPath, $Format)
    }

    [void] verify([array]$RequiredProperties)
    {
        $ConfigProperties = Get-Member -InputObject $this.config -MemberType Properties | Select-Object -ExpandProperty "Name"
        $ComparisonDifference = Compare-Object -ReferenceObject $ConfigProperties -DifferenceObject $RequiredProperties
        $MissingProperties = $ComparisonDifference | Where-Object sideIndicator -eq '=>' | Select-Object -ExpandProperty 'InputObject'
        if($MissingProperties){
            Write-Error ('Fatal Error! Config file "{0}" located in {1} missing required settings: {2}' -f ($this.Filename, $this.Path, ($MissingProperties -join ', '))) -ErrorAction Stop
        }else{
            Write-Verbose('Validation of {0} successful' -f $this.Filename)
        }
    }
}
class CSV {

    [PSCustomObject] $Data
    [String] $FullPath

    CSV([string] $FullPath)
    {
        $this.SetFullPath($FullPath)
        $this.VerifyFileExists()
        $this.SetData()
        $this.VerifyFileNotEmpty()
    }

    # Sets/Gets FullPath
    [void] SetFullPath([string] $FullPath){
        $this.FullPath = $FullPath
    }

    [string] GetFullPath()
    {
        return $this.FullPath
    }

    # Sets/Gets CSV Data
    [void] SetData(){
        $this.data = (Get-Content -Path $this.GetFullPath()) | ConvertFrom-CSV -ErrorAction Stop
    }

    [string] GetData()
    {
        return $this.Data
    }

    # Verify File Exists
    [void] VerifyFileExists()
    {
        if(-not (Test-Path $this.GetFullPath()))
        {
            throw [System.IO.FileNotFoundException]::new("Could not find CSV file: {0}" -f $this.GetFullPath(), $this.GetFullPath())
        }else{
            Write-Verbose ('CSV file {0} found' -f $this.GetFullPath())
        }
    }

    # Verify File Not Empty
    [void] VerifyFileNotEmpty()
    {
        if(-not $this.Data.Count -gt 0){
            throw [System.IO.FileFormatException]::new("CSV file {0} cannot be empty." -f $this.GetFullPath() )
        }else{
            Write-Verbose ('CSV file {0} contains {1} records' -f $this.GetFullPath(), $this.Data.Count)
        }
    }
}
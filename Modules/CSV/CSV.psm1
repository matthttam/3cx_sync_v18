class CSV {

    [PSCustomObject] $Data

    CSV([string] $FullPath)
    {
        $this.VerifyFileExists($FullPath)
        $this.SetData($FullPath)
    }

    # Sets/Gets CSV Data
    [void] SetData([string] $FullPath){
        $this.data = (Get-Content -Path $FullPath) | ConvertFrom-CSV -ErrorAction Stop
    }

    [string] GetData()
    {
        return $this.data
    }

    # Verify File Exists
    [void] VerifyFileExists($FullPath)
    {
        if(-not (Test-Path $FullPath))
        {
            throw [System.IO.FileNotFoundException]::new("Could not find CSV file: $FullPath", $FullPath)
        }else{
            Write-Verbose ('CSV file {0} found' -f $FullPath)
        }
    }
}
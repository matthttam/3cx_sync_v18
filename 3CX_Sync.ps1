Using module .\Modules\3CX\APIConnection.psm1

Using module .\Modules\CSV\CSV.psm1

Using module .\Modules\Config\ConnectionConfig.psm1
Using module .\Modules\Config\ExtensionConfig.psm1
Using module .\Modules\Config\GroupMembershipConfig.psm1
Using module .\Modules\Config\HotdeskingConfig.psm1

Using module .\Modules\Mapping\GroupMembershipMapping.psm1
Using module .\Modules\Mapping\HotdeskingMapping.psm1

Using module .\Modules\3CX\Factory\ExtensionFactory.psm1
Using module .\Modules\3CX\Factory\GroupFactory.psm1
Using module .\Modules\3CX\Factory\HotdeskingFactory.psm1

Using module .\Modules\3CX\Endpoints\ExtensionListEndpoint.psm1
Using module .\Modules\3CX\Endpoints\GroupListEndpoint.psm1
Using module .\Modules\3CX\Endpoints\HotdeskingListEndpoint.psm1

[CmdletBinding(SupportsShouldProcess)]
Param(
    [Switch] $NoExtensions,         <# Do not create or update extensions#>
    [Switch] $NoNewExtensions,      <# Do not create extensions #>
    [Switch] $NoUpdateExtensions,   <# Do not update extensions #>
    [Alias("NoGroups")]
    [Switch] $NoGroupMemberships,   <# Do not adjust any group memberships #>
    [Switch] $NoHotdesking,         <# Do not create or update hotdesking #>
    [Switch] $NoNewHotdesking,      <# Do not create hotdesking #>
    [Switch] $NoUpdateHotdesking    <# Do not update hotdesking #>
)

# Set security protocols that are supported
[Net.ServicePointManager]::SecurityProtocol = "tls12"

# Check Required Modules
if (-not (Get-Module -ListAvailable -Name PSFramework)) {
	Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module PSFramework -Scope CurrentUser -Force -Confirm:$false
} 

# Change directory
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
Set-Location $dir

# Setup Logging
$logFile = Join-Path -path $dir -ChildPath 'log' | Join-Path -ChildPath "log-$(Get-date -f 'yyyyMMdd').txt";
Set-PSFLoggingProvider -Name logfile -FilePath $logFile -Enabled $true;
Write-PSFMessage -Level Output -Message 'Sync Started'

## Import Config config.json
$ConfigPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'config.json')
$config = [ConnectionConfig]::new($ConfigPath)

## Mapping Path
$MappingPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'Mapping.json')

## Import Config\Mapping.json > Extension, GrouopMembership, Hotdesking
$ExtensionConfig = [ExtensionConfig]::New($MappingPath)
$GroupMembershipConfig = [GroupMembershipConfig]::New($MappingPath)
$HotdeskingConfig = [HotdeskingConfig]::New($MappingPath)

## Create API Connection Object
$3CXApiConnection = [APIConnection]::New($config)

# Sign In
try{
    $3CXApiConnection.login()
}catch{
    Write-Error 'Failed to connect to the 3CX Api with the provided config information.' -ErrorAction Stop
}

if(-NOT $NoExtensions){
    $NewMapping = $ExtensionConfig.Mapping.New
    $UpdateMapping = $ExtensionConfig.Mapping.Update
    $ExtensionKeyHeader = $ExtensionConfig.GetKey()
 
    ## Import Extension CSV File
    try
    {
        $ExtensionImportCSV = [CSV]::New($ExtensionConfig.GetCSVPath())
        
        #Verify ImportData isn't Empty
        if(-not $ExtensionImportCSV.Data.Count -gt 0){
            Write-Error 'Import File is Empty' -ErrorAction Stop
        }
    }
    catch
    {
        Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
    }

    
    # Get A List of Extensions
    try{
        $ExtensionListEndpoint = [ExtensionListEndpoint]::new($3CXApiConnection)
        $ExtensionList = $ExtensionListEndpoint.Get() | Select-Object -ExpandProperty 'list'
    } catch {
        Write-Error ('Failed to Look Up Extension List due to an unexpected error. ' + $PSItem.Exception.Message) -ErrorAction Stop
    }
    
    $ExtensionFactory = [ExtensionFactory]::new($3CXApiConnection)
    $Extensions = $ExtensionFactory.makeExtension($ExtensionList)
    
    #Build Lookup Table for finding the ID based on number
    $ExtensionsNumberToID = @{}
    foreach($Extension in $Extensions){
        $ExtensionsNumberToID.Add($Extension.object.number, $Extension.id)
    }

    $UpdateMappingCSVKeys = $UpdateMapping.GetMappingCSVKeys()
    $NewMappingCSVKeys = $NewMapping.GetMappingCSVKeys()

    # Loop over CSV
    foreach ($row in $ExtensionImportCSV.Data) {
        # If the row's CSVNumberHeader does exist in the extentions list, Update
        $CurrentExtensionNumber = $row.$ExtensionKeyHeader
        if($CurrentExtensionNumber -in $Extensions.object.number){
            if($NoUpdateExtensions -eq $false){
                try{
                    $CurrentExtension = $ExtensionFactory.makeExtension( $ExtensionsNumberToID[$CurrentExtensionNumber] )
                }catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Look Up Extension '{0}' due to an unexpected error. {1}" -f ($CurrentExtensionNumber, $PSItem.Exception.Message))
                    continue
                }
                

                $UpdateRequired = $false
                foreach($CSVHeader in $UpdateMappingCSVKeys)
                {
                    $CurrentExtensionValueAttributeInfo = $CurrentExtension.GetObjectAttributeInfo($UpdateMapping.GetParsedMappingValues($CSVHeader))
                    $CurrentExtensionValue = $CurrentExtension.GetObjectValue($CurrentExtensionValueAttributeInfo)
                    $CSVValue = $UpdateMapping.ConvertToType( $row.$CSVHeader, $CurrentExtensionValueAttributeInfo )
                    if( $CurrentExtensionValue -ne $CSVValue)
                    {
                        $UpdateRequired = $true
                        $payload = $CurrentExtension.GetUpdatePayload($UpdateMapping.GetParsedMappingKey($CSVHeader), $CSVValue)
                        $message = ("Staged update to extension '{0}' for field '{1}'. Old Value: '{2}' NewValue: '{3}'" -f ($CurrentExtensionNumber, $CSVHeader, $CurrentExtensionValue, $CSVValue))
                        try{
                            if ($PSCmdlet.ShouldProcess($CurrentExtensionNumber, $message))
                            {
                                $UpdateResponse = $3CXApiConnection.Endpoints.ExtensionListEndpoint.Update($payload)
                                Write-PSFMessage -Level Output -Message ($message)
                            }
                        }catch{
                            Write-PSFMessage -Level Critical -Message ("Failed to Stage Update to Extension '{0}' for CSV Header {1} due to a staging error on update parameters." -f ($row.$CSVNumberHeader, $CSVHeader))
                            continue
                        }
                    }
                }
                if($UpdateRequired){
                    try {

                        $message = ("Updated Extension: '{0}'" -f $CurrentExtensionNumber)
                        if ($PSCmdlet.ShouldProcess($CurrentExtensionNumber, $message))
                        {
                            $response = $3CXApiConnection.Endpoints.ExtensionListEndpoint.Save($CurrentExtension)
                            Write-PSFMessage -Level Output -Message ($message)
                        }
                        
                    }
                    catch {
                        Write-PSFMessage -Level Critical -Message ("Failed to Update Extension: '{0}'" -f $CurrentExtensionNumber)
                    }
                }
            }
        # If the row's CSVNumberHeader doesn't exist in the extentions list, Create
        }else{
            if($NoNewExtensions -eq $false){
                Write-Verbose ("Need to Create Extension: '{0}'" -f $CurrentExtensionNumber)
                # Begin building new extension
                try {
                    $NewExtension = $ExtensionFactory.makeExtension()
                }catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Stage Creation of New Extension '{0}' due to an unexpected error." -f ($CurrentExtensionNumber))
                    continue
                }

                foreach( $CSVHeader in $NewMappingCSVKeys)
                {
                    $NewExtensionValueAttributeInfo = $NewExtension.GetObjectAttributeInfo($NewMapping.GetParsedMappingValues($CSVHeader))
                    $CSVValue = $NewMapping.ConvertToType( $row.$CSVHeader, $NewExtensionValueAttributeInfo )
                    $payload = $NewExtension.GetUpdatePayload( $NewMapping.GetParsedMappingKey($CSVHeader) , $CSVValue)

                    $message = ("Staged update to new extension '{0}' for field '{1}'. Value: '{2}'" -f ($CurrentExtensionNumber, $CSVHeader, $CSVValue))
                    try {
                        if ($PSCmdlet.ShouldProcess($CurrentExtensionNumber, $message))
                        {
                            $UpdateResponse = $3CXApiConnection.Endpoints.ExtensionListEndpoint.Update($payload)
                            Write-PSFMessage -Level Output -Message ($message)
                        }
                    } catch {
                        Write-PSFMessage -Level Critical -Message ("Failed to Create Extension '{0}' due to a staging error on update parameters." -f ($CurrentExtensionNumber))
                        continue
                    }
                }
                try {
                    $message = ("Created Extension: '{0}'" -f $CurrentExtensionNumber)
                    if ($PSCmdlet.ShouldProcess($CurrentExtensionNumber, $message))
                    {
                        $response = $3CXApiConnection.Endpoints.ExtensionListEndpoint.Save($NewExtension)    
                        Write-PSFMessage -Level Output -Message ($message)
                    }
                }
                catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Create Extension: '{0}'" -f $CurrentExtensionNumber)
                }
            }
        }
    }
}

if(-NOT $NoGroupMemberships){
    ## Import GroupMembership CSV File
    try
    {
        $GroupMembershipImportCSV = [CSV]::New($GroupMembershipConfig.GetCSVPath())
        #Verify ImportData isn't Empty
        if(-not $GroupMembershipImportCSV.Data.Count -gt 0){
            Write-Error 'Import File is Empty' -ErrorAction Stop
        }
    }
    catch
    {
        Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
    }

    # Get GroupMembershipMapping
    $GroupMembershipMapping = $GroupMembershipConfig.Mapping.Groups
        
    # Get Groups
    try{
        $GroupListEndpoint = [GroupListEndpoint]::new($3CXApiConnection)
        $GroupList = $GroupListEndpoint.Get() | Select-Object -ExpandProperty 'list'
    }catch {
        Write-Error ('Failed to Look Up Group List due to an unexpected error. ' + $PSItem.Exception.Message) -ErrorAction Stop
    }
    
    $GroupFactory = [GroupFactory]::new($3CXApiConnection)
    $GroupMembershipMappingNames = $GroupMembershipMapping.GetNames()
    foreach( $Group in $GroupList ){
        # If this group is in the mapping file for membership management
        if($Group.Name -in $GroupMembershipMappingNames){
            try{
                # Create the group object (calls set)
                $CurrentGroup = $GroupFactory.makeGroup($Group.Id);
            }catch{
                Write-PSFMessage -Level Critical -Message ("Failed to Look Up Group '{0}' due to an unexpected error." -f ($Group.Name))
                continue
            }
            # Currently Selected Extensions that will be widdled down as we find them in the CSV
            $CachedSelected = [Collections.ArrayList] ($CurrentGroup.GetSelected())
            $ExtensionsToAdd = @()
            $ExtensionsToRemove = @()

            # Loop over CSV Data and determine what extensions should be added or removed from this group
            foreach( $row in $GroupMembershipImportCSV.Config ){
                # Determine Proper Extensions in Group
                if($GroupMembershipMapping.EvaluateConditions( $GroupMembershipMapping.config.($Group.Name).Conditions, $row) ){
                    # Null COALESCE for Powershell v5. Find                     
                    #$FoundSelected = ( ($CurrentGroup.GetSelected() | Where-Object -FilterScript {$_.Number._value -eq (""+$row.Number)}), $false -ne $null)[0]
                    $FoundSelected = ( ($CurrentGroup.GetSelectedByNumber($row.Number) ), $false -ne $null)[0]

                    # If this Number is Selected Already
                    if( $FoundSelected ){
                        $CachedSelected.Remove($FoundSelected) # Remove that number from the list
                        Continue
                    }else{
                        # Ensure this number is a possible value
                        $FoundPossibleValue = $CurrentGroup.QueryPossibleValuesByNumber($row.Number)
                        if($FoundPossibleValue){
                            # Add the found value to $ExtensionsToAdd if not already in it
                            if( -NOT ( $ExtensionsToAdd -Contains $FoundPossibleValue ) ){
                                $ExtensionsToAdd += $FoundPossibleValue  
                            }
                        }else{
                            # If not show a warning
                            Write-PSFMessage -Level Warning -Message ('Extension Number {0} not valid for group {1}' -f $row.Number, $CurrentGroup.object.Name._value)
                            continue;
                        }
                    }
                }
            }

            $ExtensionsToRemove = $CachedSelected

            # If there are extensions to add
            if($ExtensionsToAdd.count -gt 0)
            {
                # Stage Adding Members
                # If WhatIf isn't set
                if ($PSCmdlet.ShouldProcess($CurrentGroup.GetName(), $CurrentGroup.GetAddMembersMessage($ExtensionsToAdd)))
                {
                    #Stage Adding Members, continue on error
                    try{
                        $CurrentGroup.AddMembers($ExtensionsToAdd);
                    }catch{
                        continue
                    }
                }else{
                    $CurrentGroup.SetDirty($true);
                }
            }

            # If there are extensions to remove
            if($ExtensionsToRemove.count -gt 0)
            {
                # If Remove threshold has been met
                $MappingConfig.config.Extension.threshold
                # Stage Removing Members
                # If WhatIf isn't set
                if ($PSCmdlet.ShouldProcess($CurrentGroup.GetName(), $CurrentGroup.GetRemoveMembersMessage($ExtensionsToRemove)))
                {
                    #Stage Removing Members, continue on error
                    try{
                        $CurrentGroup.RemoveMembers($ExtensionsToRemove);
                    }catch{
                        continue
                    }
                }else{
                    $CurrentGroup.SetDirty($true);
                }
            }

            # Check if current group is dirty first
            if($CurrentGroup.IsDirty())
            {
                # If What If isn't set
                if ($PSCmdlet.ShouldProcess($CurrentGroup.GetName(), $CurrentGroup.GetSaveMessage()))
                {
                    # Save Any Staged Changes Group
                    try{
                        $response = $CurrentGroup.Save()
                    }catch{
                        continue
                    }
                }else{
                    $CurrentGroup.SetDirty($false)
                }
            }
        }
    }
}

if( -NOT $NoHotdesking){
    # Extract New and Update Hotdesking Mappings
    $NewMapping = $HotdeskingConfig.Mapping.New
    $UpdateMapping = $HotdeskingConfig.Mapping.Update

    ## Import Hotdesking CSV File
    try
    {
        $HotdeskingImportCSV = [CSV]::New($HotdeskingConfig.GetCSVPath())
        #Verify ImportData isn't Empty
        if(-not $HotdeskingImportCSV.Data.Count -gt 0){
            Write-Error 'Import File is Empty' -ErrorAction Stop
        }
    }
    catch
    {
        Write-Error ('Unexpected Error: ' + $PSItem.Exception.Message) -ErrorAction Stop
    }

    # Get A List of Hotdeskings from 3CX
    try{
        $HotdeskingListEndpoint = [HotdeskingListEndpoint]::new($3CXApiConnection)
        $HotdeskingList = $HotdeskingListEndpoint.Get() | Select-Object -ExpandProperty 'list'
    }catch {
        Write-Error ('Failed to Look Up Extension List due to an unexpected error. ' + $PSItem.Exception.Message) -ErrorAction Stop
    }

    # Create Hotdesking Factory
    $HotdeskingFactory = [HotdeskingFactory]::new($3CXApiConnection)
    
    # Marshal the Hotdesking List into Hotdesking objects.
    $Hotdeskings = $HotdeskingFactory.makeHotdesking($HotdeskingList)

    # Get all Macs from the listed hotdeskings
    $HotdeskingMacs = $Hotdeskings | Select-Object -ExpandProperty MacAddress

    $HotdeskingMacs = $HotdeskingList | Select-Object -ExpandProperty ($NewMapping.GetCSVHeader('MacAddress'))
    foreach( $row in $HotdeskingImportCSV.Config )
    {
        # Update Hotdesks
        if($NewMapping.ExtractValueByAPIPath('MacAddress', $row) -in $HotdeskingMacs)
        {
            continue;
        }else{
        # Create Hotdesks
            $HotdeskingCreationInfo = @{ 
                'MacAddress' = $NewMapping.ExtractValueByAPIPath('MacAddress', $row)
                'Model' = $NewMapping.ExtractValueByAPIPath('Model', $row)
            }
            Write-Verbose ("Need to Create Hotdesking: '{0}', '{1}'" -f $HotdeskingCreationInfo.MacAddress, $HotdeskingCreationInfo.Model)
            try {
                $newHotdesking = $HotdeskingFactory.makeHotdesking( $HotdeskingCreationInfo );
            }catch {
                Write-PSFMessage -Level Critical -Message ("Failed to Stage Creation of New Hotdesking '{0}', '{1}' due to an unexpected error." -f $HotdeskingCreationInfo.MacAddress, $HotdeskingCreationInfo.Model )
                continue
            }
            
            # Loop over values that need to be set
            foreach( $CSVHeader in $NewMapping.GetMappingCSVKeys())
                {
                    if($NewMapping.GetApiPath($CSVHeader) -in $HotdeskingCreationInfo.Keys )
                    {
                        continue;
                    } 

                    $CSVValue = $NewMapping.ExtractValueByCSVHeader($CSVHeader, $row)
                    $message = ("Staged update to new hotdesking '{0}',  for field '{1}'. Value: '{2}'" -f ($newHotdesking.GetName(), $CSVHeader, $CSVValue))
                    try {
                        if ($PSCmdlet.ShouldProcess($HotdeskingCreationInfo.MacAddress, $message))
                        {
                            $UpdateResponse = $HotdeskingEndpoint.Update($newHotdesking, $NewMapping.GetApiPath($CSVHeader), $CSVValue )
                            Write-PSFMessage -Level Output -Message ($message)
                        }
                    } catch {
                        Write-PSFMessage -Level Critical -Message ("Failed to Create Extension '{0}' due to a staging error on update parameters." -f ($HotdeskingCreationInfo.MacAddress))
                        continue
                    }
                }
                try {
                    $message = ("Created Hotdesking: '{0}', '{1}', '{2}" -f $newHotdesking.GetName(), $HotdeskingCreationInfo.MacAddress, $HotdeskingCreationInfo.Model)
                    if ($PSCmdlet.ShouldProcess($HotdeskingCreationInfo.MacAddress, $message))
                    {
                        $response = $HotdeskingEndpoint.Save($newHotdesking)    
                        Write-PSFMessage -Level Output -Message ($message)
                    }
                }
                catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Create Extension: '{0}'" -f $row.$CSVNumberHeader)
                }

        }
    }

}
Write-PSFMessage -Level Output -Message 'Sync Ended'
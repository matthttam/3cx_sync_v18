Using module .\Modules\3CX\APIConnection.psm1

Using module .\Modules\CSV\CSV.psm1

Using module .\Modules\Config\ConnectionConfig.psm1
Using module .\Modules\Config\ExtensionConfig.psm1
Using module .\Modules\Config\GroupConfig.psm1
Using module .\Modules\Config\GroupMembershipConfig.psm1
Using module .\Modules\Config\HotdeskingConfig.psm1

Using module .\Modules\3CX\Factory\ExtensionFactory.psm1
Using module .\Modules\3CX\Factory\GroupFactory.psm1
Using module .\Modules\3CX\Factory\HotdeskingFactory.psm1

[CmdletBinding(SupportsShouldProcess)]
Param(
    [Switch] $NoExtensions,         # Do not create or update extensions
    [Switch] $NoNewExtensions,      # Do not create extensions
    [Switch] $NoUpdateExtensions,   # Do not update extensions

    [Switch] $NoGroups,             # Do not create or update any group
    [Switch] $NoNewGroups,          # Do not create extensions
    [Switch] $NoUpdateGroups,       # Do not update extensions

    [Alias("NoGroupMembers")]
    [Switch] $NoGroupMemberships,   # Do not adjust any group memberships

    [Switch] $NoHotdesking,         # Do not create or update hotdesking
    [Switch] $NoNewHotdesking,      # Do not create hotdesking
    [Switch] $NoUpdateHotdesking,   # Do not update hotdesking
    [Switch] $Force                 # Ignore Thresholds
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
$logFile = Join-Path -path $dir -ChildPath 'log' | Join-Path -ChildPath "log-$(Get-date -f 'yyyyMMdd').txt"
Set-PSFLoggingProvider -Name logfile -FilePath $logFile -Enabled $true -MaxLevel 3
Write-PSFMessage -Level Output -Message 'Sync Started'

## Import Config config.json
$ConfigPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'config.json')
$config = [ConnectionConfig]::new($ConfigPath)

## Mapping Path
$MappingPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'Mapping.json')

## Create API Connection Object
$3CXApiConnection = [APIConnection]::New($config)

# Sign In
try{
    $3CXApiConnection.login()
}catch{
    Write-PSFMessage -Level Critical -Message ('Failed to connect to the 3CX Api with the provided config information. ' + $_.Exception.Message) -ErrorAction Stop -Exception $_.Exception
    exit(1)
}

if(-NOT $NoExtensions){
    ## Import Config\Mapping.json > Extension
    $ExtensionConfig = [ExtensionConfig]::New($MappingPath)

    $NewMapping = $ExtensionConfig.Mapping.New
    $UpdateMapping = $ExtensionConfig.Mapping.Update
    $ExtensionKeyHeader = $ExtensionConfig.GetKey()
 
    ## Import Extension CSV File
    try
    {
        $ExtensionImportCSV = [CSV]::New($ExtensionConfig.GetCSVPath())
    }
    catch
    {
        Write-PSFMessage -Level Critical -Message ($_.Exception.Message) -ErrorAction Stop -Exception $_.Exception
        exit(1)
    }

    # Initialize ExtensionFactory
    $ExtensionFactory = [ExtensionFactory]::new($3CXApiConnection)

    # Get A List of Extensions
    try{
        $Extensions = [Collections.ArrayList] $ExtensionFactory.GetExtensions()
    } catch {
        Write-PSFMessage -Level Critical -Message ('Failed to Look Up Extension List due to an unexpected error. ' + $_.Exception.Message) -ErrorAction Stop -Exception $_.Exception
        throw $_
    }

    $UpdateMappingCSVKeys = $UpdateMapping.GetCSVHeaders()
    $NewMappingCSVKeys = $NewMapping.GetCSVHeaders()

    # Loop over CSV
    foreach ($row in $ExtensionImportCSV.Data) {
        # If the row's CSVNumberHeader does exist in the extentions list, Update
        $CurrentExtensionNumber = $row.$ExtensionKeyHeader

        # If this extension number exists in 3CX
        if($CurrentExtensionNumber -in ($Extensions | ForEach-Object {$_.GetNumber()}) ){
            if($NoUpdateExtensions -eq $false){
                # Pull current extension object from the array
                $CurrentExtension = $Extensions | Where-Object { $_.GetNumber() -eq $CurrentExtensionNumber }
                
                # Populate this extension with extended fields by setting it in 3CX
                $CurrentExtension.Set()

                foreach($CSVHeader in $UpdateMappingCSVKeys)
                {
                    # Get the matched Extension Property Values
                    $ExtensionPropertyValues = $UpdateMapping.GetAPIPathByCSVHeader($CSVHeader)

                    # Convert the CSV Value using the attribute info from the current extension for this property
                    $CSVValue = $UpdateMapping.ConvertToType( $row.$CSVHeader, $CurrentExtension.GetObjectAttributeInfo($ExtensionPropertyValues) )
                    
                    # Get current extension value based on path in Mapping File for this CSV header
                    $CurrentExtensionValue = $CurrentExtension.GetObjectValue($ExtensionPropertyValues)
                    
                    # If the real extension and the CSVValue are different, queue for change
                    if( $CurrentExtensionValue -ne $CSVValue)
                    {
                        try{
                            $CurrentExtension.Update($ExtensionPropertyValues, $CSVValue)
                            Write-PSFMessage -Level Output -Message (("Staged update to extension '{0}' for field '{1}'. Old Value: '{2}' NewValue: '{3}'" -f ($CurrentExtensionNumber, $CSVHeader, $CurrentExtensionValue, $CSVValue)))
                        }catch{
                            Write-PSFMessage -Level Critical -Message ("Failed to Stage Update to Extension '{0}' for CSV Header {1} due to a staging error on update parameters." -f ($CurrentExtensionNumber, $CSVHeader))
                            continue
                        }
                    }
                }
            }

        # If the row's CSVNumberHeader doesn't exist in the extentions list, Create
        }else{
            if($NoNewExtensions -eq $false){
                Write-PSFMessage -Level Verbose -Message ("Need to Create Extension: '{0}'" -f $CurrentExtensionNumber)

                # Begin building new extension
                try{
                    $NewExtension = $ExtensionFactory.makeExtension()
                }catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Stage Creation of New Extension '{0}' due to an unexpected error." -f ($CurrentExtensionNumber))
                    continue
                }

                foreach( $CSVHeader in $NewMappingCSVKeys)
                {
                    $NewExtensionValueAttributeInfo = $NewExtension.GetObjectAttributeInfo($NewMapping.GetAPIPathByCSVHeader($CSVHeader))
                    $CSVValue = $NewMapping.ConvertToType( $row.$CSVHeader, $NewExtensionValueAttributeInfo )
                    $NewExtension.Update($NewMapping.GetAPIPathByCSVHeader($CSVHeader) , $CSVValue)
                }
                $Extensions.Add($NewExtension)
            }
        }
    }
    
    if(-NOT $force){
        $Thresholds = @(
                @{
                    'Name' = 'Disable'
                    'ExceededMessage' = "Threshold for disabling extensions exceeded. Some extensions will not be updated."
                    'CanceledMessage' = 'Update canceled for Extension {0}'
                    'ObjectsToChange' = ($Extensions | Where-Object { $_.DirtyProperties.keys -contains 'Disabled' -and $_.DirtyProperties.Disabled.NewValue -eq $True } )
                    'TotalCount' = ($ExtensionImportCSV.Data | Where-Object { -not $_.Disabled -or $_.Disabled -eq 0 }).length
                },
                @{
                    'Name' = 'Add'
                    'ExceededMessage' = "Threshold for adding extensions exceeded. Some extensions will not be updated."
                    'CanceledMessage' = 'Update canceled for Extension {0}'
                    'ObjectsToChange' = $Extensions | Where-Object {$_.IsNew() -eq $true }
                    'TotalCount' = ($ExtensionImportCSV.Data | Where-Object { -not $_.Disabled -or $_.Disabled -eq 0 }).length
                }
            )
        foreach( $Threshold in $Thresholds){
            $ExtensionConfig.ApplyThresholds($Threshold.Name, $Threshold.ObjectsToChange, $Threshold.TotalCount, $Threshold.ExceededMessage, $Threshold.CanceledMessage);
        }
    }else{
        Write-PSFMessage -Level Output -Message 'Force option used, skipping threshold checks'
    }

    # Get a list of all dirty extensions that need to be saved at this point.
    $ExtensionsToUpdate = $Extensions | Where-Object { $_.IsDirty() -eq $true }

    foreach($Extension in $ExtensionsToUpdate){
        if($Extension.IsDirty()){
            $Extension.save()
        }
    }
}

# Update Groups
if(-NOT $NoGroups){
    ## Import Config\Mapping.json > Extension
    $GroupConfig = [GroupConfig]::New($MappingPath)

    $NewMapping = $GroupConfig.Mapping.New
    $UpdateMapping = $GroupConfig.Mapping.Update
    $GroupKeyHeader = $GroupConfig.GetKey()
 
    ## Import Group CSV File
    try
    {
        $GroupImportCSV = [CSV]::New($GroupConfig.GetCSVPath())
    }
    catch
    {
        Write-PSFMessage -Level Critical -Message ($_.Exception.Message) -ErrorAction Stop -Exception $_.Exception
        exit(1)
    }

    # Initialize ExtensionFactory
    $GroupFactory = [GroupFactory]::new($3CXApiConnection)

    # Get A List of Extensions
    try{
        $Groups = [Collections.ArrayList] $GroupFactory.GetGroups()
    } catch {
        Write-Error ('Failed to Look Up Group List due to an unexpected error. ' + $PSItem.Exception.Message) -ErrorAction Stop
    }

    $UpdateMappingCSVKeys = $UpdateMapping.GetMappingCSVKeys()
    $NewMappingCSVKeys = $NewMapping.GetMappingCSVKeys()

    # Loop over CSV
    foreach ($row in $GroupImportCSV.Data) {
        # If the row's CurrentGroupKey does exist in the groups list, Update
        $CurrentGroupKey = $row.$GroupKeyHeader

        # If this extension number exists in 3CX
        if($CurrentGroupKey -in ($Groups | ForEach-Object {$_.Get($GroupKeyHeader)}) ){
            if($NoUpdateGroups -eq $false){
                # Pull current extension object from the array
                $CurrentGroup = $Groups | Where-Object { $_.Get($GroupKeyHeader) -eq $CurrentGroupKey }
                
                # Populate this extension with extended fields by setting it in 3CX
                $CurrentGroup.Set()

                foreach($CSVHeader in $UpdateMappingCSVKeys)
                {
                    # Get the matched Extension Property Values
                    $GroupPropertyValues = $UpdateMapping.GetAPIPathByCSVHeader($CSVHeader)

                    # Convert the CSV Value using the attribute info from the current extension for this property
                    $CSVValue = $UpdateMapping.ConvertToType( $row.$CSVHeader, $CurrentGroup.GetObjectAttributeInfo($GroupPropertyValues) )
                    
                    # Get current extension value based on path in Mapping File for this CSV header
                    $CurrentGroupValue = $CurrentGroup.GetObjectValue($GroupPropertyValues)
                    
                    # If the real extension and the CSVValue are different, queue for change
                    if( $CurrentGroupValue -ne $CSVValue)
                    {
                        try{
                            $CurrentGroup.Update($GroupPropertyValues, $CSVValue)
                            Write-PSFMessage -Level Output -Message (("Staged Update to Group '{0}' for field '{1}'. Old Value: '{2}' NewValue: '{3}'" -f ($CurrentGroupKey, $CSVHeader, $CurrentGroupValue, $CSVValue)))
                        }catch{
                            Write-PSFMessage -Level Critical -Message ("Failed to Stage Update to Group '{0}' for CSV Header {1} due to a staging error on update parameters." -f ($CurrentGroupKey, $CSVHeader))
                            continue
                        }
                    }
                }
            }

        # If the row's CSVNumberHeader doesn't exist in the extentions list, Create
        }else{
            if($NoNewGroups -eq $false){
                Write-Verbose ("Need to Create Group: '{0}'" -f $CurrentGroupNumber)

                # Begin building new extension
                try{
                    $NewGroup = $ExtensionFactory.makeExtension()
                }catch {
                    Write-PSFMessage -Level Critical -Message ("Failed to Stage Creation of New Group '{0}' due to an unexpected error." -f ($CurrentGroupKey))
                    continue
                }

                foreach( $CSVHeader in $NewMappingCSVKeys)
                {
                    $NewGroupValueAttributeInfo = $NewGroup.GetObjectAttributeInfo($NewMapping.GetAPIPathByCSVHeader($CSVHeader))
                    $CSVValue = $NewMapping.ConvertToType( $row.$CSVHeader, $NewGroupValueAttributeInfo )

                    $message = ("Staged update to new group '{0}' for field '{1}'. Value: '{2}'" -f ($CurrentGroupKey, $CSVHeader, $CSVValue))
                    $NewGroup.Update($NewMapping.GetAPIPathByCSVHeader($CSVHeader) , $CSVValue)
                    Write-PSFMessage -Level Output -Message ($message)
                    
                }
                $Groups.Add($NewGroup)
            }
        }
    }

    if(-NOT $force){
        $Thresholds = @(
                @{
                    'Name' = 'Delete'
                    'ExceededMessage' = "Threshold for deleting groups exceeded. Some groups will not be deleted."
                    'CanceledMessage' = 'Update canceled for group {0}'
                    'ObjectsToChange' = ($Groups | Where-Object { $_.DirtyProperties.keys -contains 'Disabled' -and $_.DirtyProperties.Disabled.NewValue -eq $True } )
                    'TotalCount' = ($ExtensionImportCSV.Data | Where-Object { -not $_.Disabled -or $_.Disabled -eq 0 }).length
                },
                @{
                    'Name' = 'Add'
                    'ExceededMessage' = "Threshold for adding groups exceeded. Some groups will not be added."
                    'CanceledMessage' = 'Update canceled for group {0}'
                    'ObjectsToChange' = $Extensions | Where-Object {$_.IsNew() -eq $true }
                    'TotalCount' = ($ExtensionImportCSV.Data | Where-Object { -not $_.Disabled -or $_.Disabled -eq 0 }).length
                }
            )
        foreach( $Threshold in $Thresholds){
            $ExtensionConfig.ApplyThresholds($Threshold.Name, $Threshold.ObjectsToChange, $Threshold.TotalCount, $Threshold.ExceededMessage, $Threshold.CanceledMessage);
        }
    }else{
        Write-PSFMessage -Level Output -Message 'Force option used, skipping threshold checks'
    }

    # Get a list of all dirty extensions that need to be saved at this point.
    $GroupsToUpdate = $GroupsToUpdate | Where-Object { $_.IsDirty() -eq $true }

    foreach($Group in $GroupsToUpdate){
        if($Group.IsDirty()){
            $Group.save()
        }
    }
}

if(-NOT $NoGroupMemberships){

    ## Import Config\Mapping.json > GroupMembership
    $GroupMembershipConfig = [GroupMembershipConfig]::New($MappingPath)

    ## Import GroupMembership CSV File

    try
    {
        $GroupMembershipImportCSV = [CSV]::New($GroupMembershipConfig.GetCSVPath())
    }
    catch
    {
        Write-PSFMessage -Level Critical -Message ($_.Exception.Message) -ErrorAction Stop -Exception $_.Exception
        exit(1)
    }

    # Get GroupMembershipMapping
    $GroupMembershipMapping = $GroupMembershipConfig.Mapping.Groups

    # Initialize GroupFactory
    $GroupFactory = [GroupFactory]::new($3CXApiConnection)

    # Get Groups
    try{
        $Groups = $GroupFactory.GetGroupsByName( $GroupMembershipMapping.GetNames() )
    }catch {
        Write-Error ('Failed to Look Up Group List due to an unexpected error. ' + $PSItem.Exception.Message) -ErrorAction Stop
    }
    
    foreach( $CurrentGroup in $Groups ){

        $CSVGroupMembers = $GroupMembershipImportCSV.Data | Where-Object {$GroupMembershipMapping.EvaluateConditions($GroupMembershipMapping.GetConditionsByGroupName($CurrentGroup.GetName()), $_) }
        
        $Comparison = $CurrentGroup.CompareMembershipByNumber($CSVGroupMembers)
        if($Comparison.comparison.count -gt 0){
            try{
                $CurrentGroup.Update(@('Members'), $Comparison.Members)

                #Delete
                $Comparison.Comparison | Where-Object {$_.SideIndicator -eq '=>'} | Select-Object -ExpandProperty 'Id'
                $ToBeDeleted = $CurrentGroup.DirtyProperties.Members.OldValue.selected | Where-Object {$_.Id -in ($Comparison.Comparison | Where-Object {$_.SideIndicator -eq '=>'} | Select-Object -ExpandProperty 'Id')}
                
                #Add
                $Comparison.Comparison | Where-Object {$_.SideIndicator -eq '<='} | Select-Object -ExpandProperty 'Id'
                $ToBeAdded = $CurrentGroup.DirtyProperties.Members.NewValue.selected | Where-Object {$_.Id -in ($Comparison.Comparison | Where-Object {$_.SideIndicator -eq '<='} | Select-Object -ExpandProperty 'Id')}
                $message = @()
                if($ToBeAdded){
                    $message += "Adding: " + ($ToBeAdded.Number._value -join ', ')
                }
                if($ToBeDeleted){
                    $message += "Deleting: " + ($ToBeDeleted.Number._value -join ', ')
                }
                $message = $message -join '. '

                Write-PSFMessage -Level Output -Message ("Staged update to Group '{0}' for membership. {1}'" -f ($CurrentGroup.GetName(), $message))
            }catch{
                Write-PSFMessage -Level Critical -Message ("Failed to Stage Update to Group '{0}' for membership. {1} due to a staging error on update parameters." -f ($CurrentGroup.GetName(), $message))
                continue
            }
        }

        # If the current group is dirty, save the changes
        if($CurrentGroup.IsDirty())
        {
            $CurrentGroup.Save()
        }
    }
}

if( -NOT $NoHotdesking){
    ## Import Config\Mapping.json > Hotdesking
    $HotdeskingConfig = [HotdeskingConfig]::New($MappingPath)
    
    # Extract New and Update Hotdesking Mappings
    $NewMapping = $HotdeskingConfig.Mapping.New
    $UpdateMapping = $HotdeskingConfig.Mapping.Update

    ## Import Hotdesking CSV File
    try
    {
        $HotdeskingImportCSV = [CSV]::New($HotdeskingConfig.GetCSVPath())
    }
    catch
    {
        Write-PSFMessage -Level Critical -Message ($_.Exception.Message) -ErrorAction Stop -Exception $_.Exception
        exit(1)
    }

    # Initialize HotdeskingFactory
    $HotdeskingFactory = [HotdeskingFactory]::new($3CXApiConnection)
    
    # Get A List of Hotdeskings from 3CX
    try{
        $Hotdeskings = $HotdeskingFactory.GetHotdeskings()
    }catch {
        Write-Error ('Failed to Look Up Extension List due to an unexpected error. ' + $PSItem.Exception.Message) -ErrorAction Stop
    }
    
    # Get all Macs from the listed hotdeskings
    $HotdeskingMacs = $Hotdeskings | Select-Object -ExpandProperty ($NewMapping.GetCSVHeader('MacAddress'))

    foreach( $row in $HotdeskingImportCSV.Data )
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

                $CSVValue = $row.$CSVHeader
                $message = ("Staged update to new hotdesking '{0}',  for field '{1}'. Value: '{2}'" -f ($newHotdesking.GetName(), $CSVHeader, $CSVValue))
                try {
                    if ($PSCmdlet.ShouldProcess($HotdeskingCreationInfo.MacAddress, $message))
                    {
                        $HotdeskingEndpoint.Update($newHotdesking, $NewMapping.GetApiPath($CSVHeader), $CSVValue ) | Out-Null
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
                    $newHotdesking.Save() | Out-Null
                    Write-PSFMessage -Level Output -Message ($message)
                }
            }
            catch {
                Write-PSFMessage -Level Critical -Message ("Failed to Create Hotdesk: '{0}'" -f $row.$CSVNumberHeader)
            }
        }
    }

}
Write-PSFMessage -Level Output -Message 'Sync Ended'
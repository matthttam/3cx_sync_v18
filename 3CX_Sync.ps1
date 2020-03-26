# FUNCTIONS
function GetValue($object, $key)
{
    $p1,$p2 = $key.Split(".")
    if($p2) { return GetValue -object $object.$p1 -key $p2 }
    else { return $object.$p1 }
}

function SetValue($object, $key, $Value)
{
    $p1,$p2 = $key.Split(".")
    if($p2) { SetValue -object $object.$p1 -key $p2 -Value $Value }
    else { $object.$p1 = $Value }
}

function Test-ConfigPath($path)
{
    $filename = $path | Split-Path -Leaf
    if(-not (Test-Path -Path $path )){
        Write-Warning ('{0} not located in {1}.' -f $filename, $path )
        return $false
    }
    return $true
}

# Change directory
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
Set-Location $dir

## Verify Config Files Exist
# Verify Config Exists
$ConfigPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'config.json')
if(-not (Test-ConfigPath -path $ConfigPath))
{
    $response = Read-Host 'Run Setup script? [Yn]'
    if($response -eq '' -or $response.ToLower() -eq 'y'){
        & "$dir\Setup.ps1"
    }else{
        Write-Error 'Exitting. config is required to run this sync.'
        exit
    }
}else{
    Write-Verbose 'Config.json found'
}

# Verify NewMapping Exists
$NewMappingPath = (Join-Path -Path $dir -ChildPath 'Config' | Join-Path -ChildPath 'NewMapping.json')
if(-not (Test-ConfigPath -path $NewMappingPath))
{
    Write-Error 'Exitting. NewMapping is required to run this sync.' -ErrorAction Stop
    exit
}else{
    Write-Verbose 'NewMappingPath.json found'
}

## Read Config FIles
# Read Config File
try{
    $config = (Get-Content -Path $ConfigPath) | ConvertFrom-Json -ErrorAction Stop # Read Config and convert to json object
    $config.BaseUrl = $config.BaseUrl.Trim('/') # Remove trailing slash
}catch{
    Write-Error -Message 'Fatal Error! Unable to read config.json'
    exit
}

# Read NewMapping File
try{
    $NewMapping = (Get-Content -Path $NewMappingPath) | ConvertFrom-Json -ErrorAction Stop # Read Config and convert to json object
}catch{
    Write-Error -Message 'Fatal Error! Unable to read NewMapping.json'
    exit
}

## Verify CSV Files exit
$ImportFilePath = (Join-Path -Path $dir -ChildPath 'Import Files' | Join-Path -ChildPath $config.ImportFilename)
if(-not (Test-ConfigPath -path $ImportFilePath))
{
    Write-Error 'Exitting. Import file specified in config not found.' -ErrorAction Stop
    exit
}else{
    Write-Verbose  ('{0} found' -f $config.ImportFilename)
}

# Read in CSV File
try{
    $ImportData = (Get-Content -Path $ImportFilePath) | ConvertFrom-Csv -ErrorAction Stop # Read Config and convert to json object
}catch{
    Write-Error -Message ('Fatal Error! Unable to read {0}' -f $config.ImportFilename)
    exit
}

## Verify Config Files
#Verify ImportData isn't Empty
if(-not $ImportData.Count -gt 0){
    Write-Error 'Import File is Empty'
    exit
}

# Verify Config Variables
$ConfigProperties = Get-Member -InputObject $config -MemberType Properties | Select-Object -ExpandProperty "Name"
$RequiredProprties = @('BaseUrl','Password','Username','ImportFilename')
$ComparisonDifference = Compare-Object -ReferenceObject $ConfigProperties -DifferenceObject $RequiredProprties
if($ComparisonDifference){
    $ComparisonDifferences | where sideIndicator -eq '=>' | Select-Object -ExpandProperty 'InputObject'
    Write-Error ('Fatal Error! Config missing required settings: {0}' -f ($ComparisonDifference -join ', '))
    exit
}

# Verify NewMapping has required fields
$CSVExtensionNumberField = $NewMapping.PSObject.Properties | Where-Object {$_.Value -eq 'Number'} | Select-Object -ExpandProperty 'Name'
if(-not $CSVExtensionNumberField){
    Write-Error ('Fatal Error! NewMapping missing required field Number')
    exit
}

# Decrypt Password
$config.Password = $config.Password | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($config.Password)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$Credentials = ((@{
    Username = $config.Username
    Password = $PlainPassword
}) | ConvertTo-Json)

# Login
$LoginResponse = Invoke-WebRequest -Uri ('{0}/login' -f $config.BaseUrl) -Method Post -ContentType "application/json;charset=UTF-8" -Body $Credentials.ToString() -SessionVariable 'Session'

if( $LoginResponse.Content -ne 'AuthSuccess' ){
    Write-Error 'Failed to authenticate' -ErrorAction Stop
}

# Store XSRF token for use in header
$Cookies = $Session.Cookies.GetCookies($login_url)
$XSRF = ($Cookies | where  name -eq "XSRF-TOKEN").Value

$DefaultConnectionSettings = @{
    WebSession = $Session
    Method = 'Get'
    Headers = @{"x-xsrf-token"="$XSRF"}
    ContentType = "application/json;charset=UTF-8"
}

#$test5 = Invoke-WebRequest -Uri "https://owensboro.my3cx.us:5001/api/ExtensionList/set" -WebSession $Session -Method "POST" -Headers @{"x-xsrf-token"="$XSRF"} -ContentType "application/json;charset=UTF-8" -Body "{`"Id`":`"00000`"}"
#$test5.Content

# Get A List of Extensions
$Response = Invoke-WebRequest -Uri ('{0}/ExtensionList' -f $config.BaseUrl) @DefaultConnectionSettings
$ExtensionList = $Response.Content | ConvertFrom-Json | Select-Object -ExpandProperty 'list'

$ExtensionListNumber = $ExtensionList | Select-Object -ExpandProperty Number
$Queue_ExtensionNew = @();
$Queue_ExtensionUpdate = [System.Collections.ArrayList] @();

function ParseMapping(){
    params(
        $Mapping
}
    $return = $NewMapping.PSObject.Properties | Select-Object -ExpandProperty 'Value'
}

function New-3CXExtension()
{
    return 
}

function BuildExtensionUpdateParameters(){
    params(
        $ObjectID,
        $Mapping,
        $Data
    )
    $CSVHeaders = $Mapping.PSObject.Properties | Select-Object -ExpandProperty 'Name'
    $3CXPaths = $NewMapping.PSObject.Properties | Select-Object -ExpandProperty 'Value'
    foreach($
    $return = @{
        #Path = @{
        #    
        #},
        #PropertyValue = '00001ab'
    }

    #{"Path":{"ObjectId":"40","PropertyPath":[{"Name":"Number"}]},"PropertyValue":"00001ab"}


    return @{}
}

# Loop over CSV
foreach ($row in $ImportData) {
    #If it exists, skip
    if($row.$CSVExtensionNumberField -in $ExtensionListNumber){
        continue;
        # Todo - Determine if certain fields are different and if they are queue for update
    }else{
        $Queue_ExtensionNew += $row
        Write-Verbose ('Need to Create {0}' -f $row.Number)
    }

# If it doesn't exist, Create
}
$Queue_ExtensionNew

#$test = $Queue_ExtensionCreation | Where Number -eq '07936'
#$new = Invoke-WebRequest -Uri ('{0}/ExtensionList/New' -f $config.BaseUrl) -WebSession $Session -Method Post -Headers @{"x-xsrf-token"="$XSRF"} -ContentType "application/json;charset=UTF-8"


# Mapping File to map csv headers to Object Paths

# CSVHeader = DOTPath 
# Set ActiveObject:
# _str = Number #extension
# ExtensionDID
# Setup Variables
<#
$mapping = @{
    'Number' = 'Number'
    'FirstName' = 'FirstName'
    'LastName' = 'LastName'
    'EmailAddress' = 'Email'
    #'MobileNumber' = 'MobileNumber'
    #'AuthID' = 'AuthId' #RandomString
    #'AuthPassword' = 'AuthPassword' #RandomString
    #'WebMeetingFriendlyName' = 'ExternalAccess.WebMeetingFriendlyName' #""
    #'WebMeetingPrivateRoom' = ''
    #'ClickToCall' = ''
    #'ClickToCallFriendlyName' = ''
    #'WebMeetingAcceptReject' = 'ExternalAccess.WebMeetingAcceptReject'
    #'EnableVoicemail' = ''
    #'VMNoPin' = ''
    #'VMPlayCallerID' = ''
    'PIN' = 'VMPin'
    #'VMPlayMsgDateTime' = ''
    'VMEmailOptions' = 'VMEmailOptions'
    #'QueueStatus' = ''
    'OutboundCallerID' = 'OutboundCallerId'
    #'SIPID' = '' #blank
    #'DeliverAudio' = ''
    #'SupportReinvite' = 'CapabilityReInvite' #True
    #'SupportReplaces' = 'CapabilityReplacesHeader' #True
    #'EnableSRTP' = ''
    #'ManagementAccess' = ''
    #'ReporterAccess' = ''
    #'WallboardAccess' = '?'
    #'TurnOffMyPhone' = 'MyPhoneDisallowUse' #?? MyPhoneUseIn3cxPhoneEnabled #False
    #'HideFWrules' = 'MyPhoneHideForwardings' #False
    #'CanSeeRecordings' = 'MyPhoneShowRecordings' #False
    #'CanDeleteRecordings' = 'MyPhoneAllowDeleteRecordings' #False
    #'RecordCalls' = 'RecordCalls' #False
    #'CallScreening' = 'CallScreening' #False
    'EmailMissedCalls' = 'SendEmailMissedCalls'
    'Disabled' = 'Disabled'
    #'DisableExternalCalls' = 'InternalCallsOnly' #False
    #'AllowLanOnly' = 'AllowLanOnly' #True
    #'BlockRemoteTunnel' = 'BlockRemoteTunnel' #False
    # 'PinProtect' = 'PinProtected' #False
    #'MAC_0' = 'MacAddress' #""
    #'InterfaceIP_0' = 'MyPhoneLocalInterface' #0th index (first in list)
    #'UseTunnel' = 'MyPhoneUseTunnel' #True
    #'DND' = '' # ??CurrentProfile
    #'UseCTI' = 'MyPhoneUseIn3cxPhoneMode' # Need to set this to 0 actually... this is confusing Correct value is index 0 "UseIn3cxPhoneMode.UseCti" #Default 1
    'MyPhoneUseIn3cxPhoneMode' = 'MyPhoneUseIn3cxPhoneMode' # 0 = UseIn3cxPhoneMode.UseCti, 1 = UseIn3cxPhoneMode.SipPhone
    'StartupScreen' = 'MyPhoneStartUpScreen' #0 = StartUpScreenMode.DialPad
    #'HotelModuleAccess' = '' # ??
    #'DontShowExtInPHBK' = 'HideInPhonebook' #False
    #'DeskphoneWebPass' = 'DeskphonePassword'
    'SrvcAccessPwd' = 'AccessPassword'
    #'VoipAdmin' = '' #??
    #'SysAdmin' = '' #??
    #'SecureSIP' = '' #??
    #'PhoneModel14' = '' #??
    #'PhoneTemplate14' = '' #??
    #'CustomTemplate' = '' #??
    #'PhoneSettings' = '' #??
    #'AllowAllRecordings' = '' #?? All recording things are false by default
    #'PushExtension' = 'MyPhonePush' #True
    #'Integration' = 'IntegrationEnabled' #False
    #'AllowOwnRecordings' = 'AllowOwnRecordings' #True
    #'RecordExternalCallsOnly' = 'RecordCalls' #0 = RecordCallsOption.RecordingsOff
    #'DID' = 'ExtensionDID' #BlankArray
    'AllowToUseHotdesking' = 'AllowToUseHotdesking'
}

$ForwardingOptions = @{
            'ForwardType' = '' # @('TypeOfExtensionForward.VoiceMail','TypeOfExtensionForward.ExtensionVoiceMail','TypeOfExtensionForward.MobileNumber','TypeOfExtensionForward.DN','TypeOfExtensionForward.ExternalNumber','TypeOfExtensionForward.EndCall')
            'VMailDN' = '' # ONLY TypeOfExtensionForward.ExtensionVoiceMail
            'ForwardDN' = '' # ONLY TypeOfExtensionForward.DN
            'ExternalNumber' = '' # ONLY TypeOfExtensionForward.MobileNumber
            'Rebound' = $false # ONLY TypeOfExtensionForward.MobileNumber OR TypeOfExtensionForward.DN OR TypeOfExtensionForward.MobileNumber
        }

$UpdateValues = @{
    'Disabled' = $false
    'Number' = '12345'
    'FirstName' = 'firstname'
    'LastName' = 'lastname'
    'Email' = 'email'
    'MobileNumber' = ''
    'OutboundCallerId' = '2706861000'
    #'AuthId' = 'AuthId' #RandomString
    #AuthPassword = 'AuthPassword' #RandomString
    'AccessWebClient' = $true
    #'AccessPassword' = 'AccessPassword' #RandomString
    #'ExtensionDID' = @('1235551000')
    #'VMLanguage' = 0 # English
    'VMPin' = '1234'
    'VMReadDateTimeMessage' = 'ReadDateTimeMessageType.DoNotRead' # @('ReadDateTimeMessageType.DoNotRead', 'ReadDateTimeMessageType.ReadIn12hFormat', 'ReadDateTimeMessageType.ReadIn24hFormat')
    'VMEmailOptions' = 'EmailNotificationType.SendVMailAsAttachmentAndDelete'# @('EmailNotificationType.DoNotSend', 'EmailNotificationType.SendTextOnly', 'EmailNotificationType.SendVMailAsAttachment', 'EmailNotificationType.SendVMailAsAttachmentAndDelete')
    'VMDisablePinAuth' = $false
    'VMPlayCallerId' = $false
    'ForwardingAvailable' = @{
        'NoAnswerTimeout' = '' # If I do not answer calls within: X seconds. Forward internal calls to:
        'NoAnswerInternalForwarding' = $ForwardingOptions.Clone() # If I do not answer calls within: X seconds. Forward internal calls to:
        'BusyInternalForwarding' = $ForwardingOptions.Clone() # If I am busy or my phone is unregistered, forward calls to:
        'NoAnswerForwarding' = $ForwardingOptions.Clone() # After timeout forward external calls to:
        'BusyForwarding' = $ForwardingOptions.Clone() # If I am busy or my phone is unregistered, forward calls to:
        # Options
        'RingExtensionAndMobile' = $false # Ring my mobile simultaneously
        'AcceptMultipleCalls' = $false # Accept multiple calls
        'OfficeHoursAutoQueueLogOut' = $false# Log out from queues
        'AcceptRingGroupCalls' = $true# Accept calls from Ring Groups
        'BlockPushCalls' = $true # Accept Push Notifications
    }
    #'ForwardingAway' = @{} # Away
    #'ForwardingAway2' = @{} # Do Not Distrurb
    # Lunch and Teaching are custom profile names
    # Invoke-WebRequest -Uri "https://owensboro.my3cx.us:5001/api/CustomParametersList/getCustomProfileNames" -Headers @{"method"="GET"; "authority"="owensboro.my3cx.us:5001"; "scheme"="https"; "path"="/api/CustomParametersList/getCustomProfileNames"; "pragma"="no-cache"; "accept"="application/json, text/plain, */*"; "cache-control"="no-cache"; "sec-fetch-dest"="empty"; "x-xsrf-token"="CfDJ8BImnUu2n89OgDb4SU0Gs1ZkKZpextbOUv4t7gO_L8Jp8aBOnsME4u3gIVLck2LSVh1X6laI3Vrr6A0645YEtErxVHDPZcyepqNoZ6ivGagNKBtT3yNFGrh2iQ4D1cYeV17ADRdCAxBFz7ox8KAaVeRYFogiWPrP_FlpuRx-we0U"; "user-agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"; "sec-fetch-site"="same-origin"; "sec-fetch-mode"="cors"; "referer"="https://owensboro.my3cx.us:5001/"; "accept-encoding"="gzip, deflate, br"; "accept-language"="en-US,en;q=0.9"; "cookie"=".AspNetCore.Webclient=CfDJ8BImnUu2n89OgDb4SU0Gs1bjCUAOGUf22-BvYlVyfoAI5OdHvf9fU-obafMNT7rRe0Zq09tyIB5Q53rsMOzm6CKTcVPyd_qbUVLhCvOp0CS4qaw4dgdx-Val5iXWVqUsbOXvG0JX3Mim12gQJdQmhEV7iRfz0lAS3z2svZZbmVDjzrxQf49vLBQQNqUo5fhAir_Ajv7iBDPeLGQp_o49oaa55HxzzBNTNxN6NVaMAcwFJwb6WQEYAzw0-aON7n4EHbVkMTC_C4aN44mEpBmpdeZDHQp8E7_bJGhaP95x3MTxPCipiEw02wdXQ0WYCrcDWeNc4MB_cHhwcIQj25TF9BJDYpqRvSN43vdVIWd3bz-oVW79jrJn9mVXm7IjqOw5M_SCJ3veMiABlZrwI2nGG0wa9bHJtrozsExC9n0tOkQy5ubmDl4bupFYJQppR3pkPg; CmmSession=58c1db7a-21bb-98f8-3877-26a24d86f412; .AspNetCore.Cookies=CfDJ8BImnUu2n89OgDb4SU0Gs1Yz222t_Uv_6CYhUdyNBI56u_Hs4hlP4NbbOZoWi7g1d2v4pszq24DG3dt-xjVHWRazhg7UlSmzpR6ROuOUiI5ikpo_119-y-Gbdh158hhYTbp_apvx8VkNJ7c61J4Q2KE9XyiUcqQQSv1MKNOG9f9NULAfwq8h50lRw78i5Qopv3DrdsYNoPGxBgGIR8WmYIL5-nKa8bA_r54_6HixiVfu8cSg2QS6k9gKdc2FWpRIl46JE_2EOBU1L_8LlDI8vRChymQ4jCz2xEheyey5X4oq9B2O7DTCWUskE9eVOB5ncsQdHMFPMOIOeVb2fY7Tn61AEik3lGM2HG5fLi57pOSQsdt_Mj1HAeHwCNCuIq5iuwt30TnHG2mCOi1H9UjNeAa-BFmzlVGprfTvfa-ZkRKv; XSRF-TOKEN=CfDJ8BImnUu2n89OgDb4SU0Gs1ZkKZpextbOUv4t7gO_L8Jp8aBOnsME4u3gIVLck2LSVh1X6laI3Vrr6A0645YEtErxVHDPZcyepqNoZ6ivGagNKBtT3yNFGrh2iQ4D1cYeV17ADRdCAxBFz7ox8KAaVeRYFogiWPrP_FlpuRx-we0U"}
    #'ForwardingAvailable2' = @{} #Lunch
    #'ForwardingAway3' = @{} #Teaching
    #
    # TODO Greetings
    'OfficeHoursAutoSwitchProfiles' = $false # TODO Office Hour Configurations
    # TODO Forwarding Rules > Exceptions
    # TODO Phone Provisioning > Your phones
    # TODO
    'MyPhoneLocalInterface' = ''
    'MyPhoneSipTransport' = '' # @('MyPhoneSipTransportType.UDP','MyPhoneSipTransportType.TCP', 'MyPhoneSipTransportType.TLS')
    'MyPhoneRtpMode' = '' # @('MyPhoneRtpModeType.Normal','MyPhoneRtpModeType.AllowSecure','MyPhoneRtpModeType.OnlySecure')
}

#>
# Update the New Record

#Invoke-WebRequest -Uri "https://owensboro.my3cx.us:5001/api/edit/update" -Method "POST" 
#-Headers @{"method"="POST"; "authority"="owensboro.my3cx.us:5001"; "scheme"="https"; "path"="/api/edit/update"; "accept"="application/json, text/plain, */*"; "sec-fetch-dest"="empty"; "x-xsrf-token"="CfDJ8BImnUu2n89OgDb4SU0Gs1ZkKZpextbOUv4t7gO_L8Jp8aBOnsME4u3gIVLck2LSVh1X6laI3Vrr6A0645YEtErxVHDPZcyepqNoZ6ivGagNKBtT3yNFGrh2iQ4D1cYeV17ADRdCAxBFz7ox8KAaVeRYFogiWPrP_FlpuRx-we0U"; "user-agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"; "origin"="https://owensboro.my3cx.us:5001"; "sec-fetch-site"="same-origin"; "sec-fetch-mode"="cors"; "referer"="https://owensboro.my3cx.us:5001/"; "accept-encoding"="gzip, deflate, br"; "accept-language"="en-US,en;q=0.9"; "cookie"=".AspNetCore.Webclient=CfDJ8BImnUu2n89OgDb4SU0Gs1bjCUAOGUf22-BvYlVyfoAI5OdHvf9fU-obafMNT7rRe0Zq09tyIB5Q53rsMOzm6CKTcVPyd_qbUVLhCvOp0CS4qaw4dgdx-Val5iXWVqUsbOXvG0JX3Mim12gQJdQmhEV7iRfz0lAS3z2svZZbmVDjzrxQf49vLBQQNqUo5fhAir_Ajv7iBDPeLGQp_o49oaa55HxzzBNTNxN6NVaMAcwFJwb6WQEYAzw0-aON7n4EHbVkMTC_C4aN44mEpBmpdeZDHQp8E7_bJGhaP95x3MTxPCipiEw02wdXQ0WYCrcDWeNc4MB_cHhwcIQj25TF9BJDYpqRvSN43vdVIWd3bz-oVW79jrJn9mVXm7IjqOw5M_SCJ3veMiABlZrwI2nGG0wa9bHJtrozsExC9n0tOkQy5ubmDl4bupFYJQppR3pkPg; CmmSession=58c1db7a-21bb-98f8-3877-26a24d86f412; .AspNetCore.Cookies=CfDJ8BImnUu2n89OgDb4SU0Gs1Yz222t_Uv_6CYhUdyNBI56u_Hs4hlP4NbbOZoWi7g1d2v4pszq24DG3dt-xjVHWRazhg7UlSmzpR6ROuOUiI5ikpo_119-y-Gbdh158hhYTbp_apvx8VkNJ7c61J4Q2KE9XyiUcqQQSv1MKNOG9f9NULAfwq8h50lRw78i5Qopv3DrdsYNoPGxBgGIR8WmYIL5-nKa8bA_r54_6HixiVfu8cSg2QS6k9gKdc2FWpRIl46JE_2EOBU1L_8LlDI8vRChymQ4jCz2xEheyey5X4oq9B2O7DTCWUskE9eVOB5ncsQdHMFPMOIOeVb2fY7Tn61AEik3lGM2HG5fLi57pOSQsdt_Mj1HAeHwCNCuIq5iuwt30TnHG2mCOi1H9UjNeAa-BFmzlVGprfTvfa-ZkRKv; XSRF-TOKEN=CfDJ8BImnUu2n89OgDb4SU0Gs1ZkKZpextbOUv4t7gO_L8Jp8aBOnsME4u3gIVLck2LSVh1X6laI3Vrr6A0645YEtErxVHDPZcyepqNoZ6ivGagNKBtT3yNFGrh2iQ4D1cYeV17ADRdCAxBFz7ox8KAaVeRYFogiWPrP_FlpuRx-we0U"}
# -ContentType "application/json;charset=UTF-8" -Body "{`"Path`":{`"ObjectId`":`"5`",`"PropertyPath`":[{`"Name`":`"FirstName`"}]},`"PropertyValue`":`"TEST`"}"

# Save
#Invoke-WebRequest -Uri "https://owensboro.my3cx.us:5001/api/edit/save" -Method "POST" 
#-Headers @{"method"="POST"; "authority"="owensboro.my3cx.us:5001"; "scheme"="https"; "path"="/api/edit/save"; "accept"="application/json, text/plain, */*"; "sec-fetch-dest"="empty"; "x-xsrf-token"="CfDJ8BImnUu2n89OgDb4SU0Gs1ZkKZpextbOUv4t7gO_L8Jp8aBOnsME4u3gIVLck2LSVh1X6laI3Vrr6A0645YEtErxVHDPZcyepqNoZ6ivGagNKBtT3yNFGrh2iQ4D1cYeV17ADRdCAxBFz7ox8KAaVeRYFogiWPrP_FlpuRx-we0U"; "user-agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"; "origin"="https://owensboro.my3cx.us:5001"; "sec-fetch-site"="same-origin"; "sec-fetch-mode"="cors"; "referer"="https://owensboro.my3cx.us:5001/"; "accept-encoding"="gzip, deflate, br"; "accept-language"="en-US,en;q=0.9"; "cookie"=".AspNetCore.Webclient=CfDJ8BImnUu2n89OgDb4SU0Gs1bjCUAOGUf22-BvYlVyfoAI5OdHvf9fU-obafMNT7rRe0Zq09tyIB5Q53rsMOzm6CKTcVPyd_qbUVLhCvOp0CS4qaw4dgdx-Val5iXWVqUsbOXvG0JX3Mim12gQJdQmhEV7iRfz0lAS3z2svZZbmVDjzrxQf49vLBQQNqUo5fhAir_Ajv7iBDPeLGQp_o49oaa55HxzzBNTNxN6NVaMAcwFJwb6WQEYAzw0-aON7n4EHbVkMTC_C4aN44mEpBmpdeZDHQp8E7_bJGhaP95x3MTxPCipiEw02wdXQ0WYCrcDWeNc4MB_cHhwcIQj25TF9BJDYpqRvSN43vdVIWd3bz-oVW79jrJn9mVXm7IjqOw5M_SCJ3veMiABlZrwI2nGG0wa9bHJtrozsExC9n0tOkQy5ubmDl4bupFYJQppR3pkPg; CmmSession=58c1db7a-21bb-98f8-3877-26a24d86f412; .AspNetCore.Cookies=CfDJ8BImnUu2n89OgDb4SU0Gs1Yz222t_Uv_6CYhUdyNBI56u_Hs4hlP4NbbOZoWi7g1d2v4pszq24DG3dt-xjVHWRazhg7UlSmzpR6ROuOUiI5ikpo_119-y-Gbdh158hhYTbp_apvx8VkNJ7c61J4Q2KE9XyiUcqQQSv1MKNOG9f9NULAfwq8h50lRw78i5Qopv3DrdsYNoPGxBgGIR8WmYIL5-nKa8bA_r54_6HixiVfu8cSg2QS6k9gKdc2FWpRIl46JE_2EOBU1L_8LlDI8vRChymQ4jCz2xEheyey5X4oq9B2O7DTCWUskE9eVOB5ncsQdHMFPMOIOeVb2fY7Tn61AEik3lGM2HG5fLi57pOSQsdt_Mj1HAeHwCNCuIq5iuwt30TnHG2mCOi1H9UjNeAa-BFmzlVGprfTvfa-ZkRKv; XSRF-TOKEN=CfDJ8BImnUu2n89OgDb4SU0Gs1ZkKZpextbOUv4t7gO_L8Jp8aBOnsME4u3gIVLck2LSVh1X6laI3Vrr6A0645YEtErxVHDPZcyepqNoZ6ivGagNKBtT3yNFGrh2iQ4D1cYeV17ADRdCAxBFz7ox8KAaVeRYFogiWPrP_FlpuRx-we0U"} 
#-ContentType "application/json;charset=UTF-8" -Body "4"
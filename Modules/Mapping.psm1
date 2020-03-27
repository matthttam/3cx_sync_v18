Using module .\Config.psm1

class Mapping : Config
{
    [array]$ParsedConfig
    Mapping([string]$a) : base($a)
    {
        $this.ParseConfig($this.Config)
    }

    [void] ParseConfig([PSCustomObject] $config)
    {
        # NOT DONE YET
        $APIPaths = Get-Member -InputObject $this.config -MemberType Properties | Select-Object -ExpandProperty "Name"
        foreach($Path in $APIPaths){
            # CSV Header: $this.Config.$Path
            $PropertyPath = @()
            foreach($PathName in ($Path -split '\.')){
                $PropertyPath = $PropertyPath + @{"Name"=$PathName}
            }
            $this.ParsedConfig = $this.ParsedConfig + @{
                "PropertyPath" = $PropertyPath
                "PropertyValueHeader" = $this.Config.$Path
            }
            #$blah = @{
            #    "PropertyPath" = @()
            #}
        }
    }

       <# $return = 
        @(
            
            @{
                 "PATH" = @(
                        @{"Name"="ForwardingAvailable"},
                        @{"Name"="BusyInternalForwarding"},
                        @{"Name"="ForwardType"}
                    )
                "PropertyValueHeader" = "CSVHEADERVALUE"
            },
            @{
                "PATH" = @(
                       @{"Name"="ForwardingAvailable"},
                       @{"Name"="NoAnswerForwarding"},
                       @{"Name"="ForwardType"}
                   )
               "PropertyValueHeader" = "CSVHEADERVALUE2"
           }
        )
        {
            "Path":
            {
                "ObjectId":"5",
                "PropertyPath":
                [
                    {"Name":"ForwardingAvailable"},
                    {"Name":"BusyInternalForwarding"},
                    {"Name":"ForwardType"}
                ]
            },
            "PropertyValue":"TypeOfExtensionForward.MobileNumber"
        }
            #>
    
    
}
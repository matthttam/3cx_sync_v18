Using module .\Config.psm1
Using module ..\Mapping\GroupMembershipMapping.psm1

class GroupMembershipConfig : Config
{
    # Name of Node From Config File to Store
    [string] $ConfigNode = 'GroupMembership'
    [hashtable] $Mapping = @{}
    [array] $RequiredFields = @('Groups')
    [hashtable] $Threshold = @{ "AddMembers" = $false; "RemoveMembers" = $false}

    GroupMembershipConfig( [string] $FullPath ) : base($FullPath){
        # Create Mapping for Groups
        $this.Mapping.Groups = [GroupMembershipMapping]::new($this.Config.Groups)

        # Store Threshold Values
        if($this.config.Threshold.AddMembers){
            $this.SetThreshold("Add", $this.config.Threshold.Add)
        }
        if($this.config.Threshold.RemoveMembers){
            $this.SetThreshold("Remove", $this.config.Threshold.Remove)
        }
    }

}
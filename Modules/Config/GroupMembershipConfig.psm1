Using module .\Config.psm1
Using module ..\Mapping\GroupMembershipMapping.psm1

class GroupMembershipConfig : Config
{
    # Name of Node From Config File to Store
    [string] $ConfigNode = 'GroupMembership'
    [hashtable] $Mapping = @{}
    [array] $RequiredFields = @('Groups')

    GroupMembershipConfig( [string] $FullPath ) : base($FullPath){
        # Create Mapping for Groups
        $this.Mapping.Groups = [GroupMembershipMapping]::new($this.Config.Groups)
    }

}
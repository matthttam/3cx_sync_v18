Using module .\Mapping.psm1

class GroupMembershipMapping : Mapping
{
    # Hashtable mapping CSV Headers to an array of Objects containing API Names
    #[hashtable]$ParsedConfig = @{}
    [PSCustomObject]$Mapping

    GroupMembershipMapping([PSCustomObject] $config) : base($config)
    {
    }

    [boolean] EvaluateConditions([array]$Conditions, $row){
        if($Conditions -eq $null){
            throw 'Unable to evaluate null conditions'
        }
        $return = $true
        foreach($Condition in $Conditions){
            if($row.($Condition.Field) -ne $Condition.Value){
                $return = $false
            }
        }
        return $return
    }
}
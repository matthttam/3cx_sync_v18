Using module .\Mapping.psm1

class GroupMembershipMapping : Mapping
{

    GroupMembershipMapping([PSCustomObject] $mapping) : base($mapping)
    {
    }

    [array] GetNames(){
        return $this.Mapping.Keys
    }
    
    [array] GetConditionsByGroupName($Name){
        return $this.Mapping.$Name.Conditions
    }

    [boolean] EvaluateConditions([array]$Conditions, $row){
        if($null -eq $Conditions){
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
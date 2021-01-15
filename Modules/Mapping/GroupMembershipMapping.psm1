Using module .\Mapping.psm1

class GroupMembershipMapping : Mapping
{
    # Hashtable mapping CSV Headers to an array of Objects containing API Names
    #[hashtable]$ParsedConfig = @{}
    [PSCustomObject]$Mapping

    GroupMembershipMapping([PSCustomObject] $config) : base($config)
    {
    }

    [array] GetNames(){
        return $this.Mapping | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
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
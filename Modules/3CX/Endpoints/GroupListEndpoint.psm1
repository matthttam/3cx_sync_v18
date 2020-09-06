Using module .\Endpoint.psm1

Class GroupListEndpoint : Endpoint
{
    
    GroupListEndpoint($APIConnection) : base($APIConnection)
    {
        $this.SetEndpointPath('GroupList')
    }

    [PSObject] QueryPossibleValues($group, $state)
    {
        $payload = @{
            "Path" = @{
                "ObjectId" = $group.Id
                "PropertyPath" = @(@{"Name" = "Members"})
            }
            "State" = $state
            "Count" = "100" # Incrase number of results returned per query
        }
        $PossibleValues = [System.Collections.ArrayList] @()

        #Cycle through pagination
        Do{
            #$response = $this.QueryPossibleValues($group, $state)
            $response = $this.ReadProperty($payload)
            $PossibleValues += $response.PossibleValues
            $State.start += $payload.Count#$group.object.Members.itemsByPage
        }while( $State.start -lt $response.count )
        return $PossibleValues

        #return $this.ReadProperty($payload)
    }

    [PSObject] QueryMembers( $group, $state )
    {
        $payload = @{
            "Path" = @{
                "ObjectId" = $group.Id
                "PropertyPath" = @(@{"Name" = "Members"})
            }
            "PropertyValue" = @{"State" = $state}
        }
        $Members = [System.Collections.ArrayList] @()
        Do{
            $response = $this.Update($payload)
            $Members += $response.Item.Members.Selected
            $State.start += $group.object.Members.itemsByPage
        }while( $State.start -lt $group.object.Members.count )
        
        return $Members
    }

    [PSObject] RemoveMembers( $group, $members )
    {
        $payload = $this.GetPayloadBody()
        $payload.Path.ObjectId = $group.Id
        $payload.Path.PropertyPath += @{"Name" = "Members"}
        $payload.PropertyValue = @{"Delete" = @{"Ids" = @($members.Id); "IsAllSelected" = $false; "Search" = ""}}
        $response = $this.Update($payload)
        $group.SetDirty($true)
        return $response 
    }

    [PSObject] AddMembers( $group, $members )
    {
        $payload = $this.GetPayloadBody()
        $payload.Path.ObjectId = $group.Id
        $payload.Path.PropertyPath += @{"Name" = "Members"}
        $payload.PropertyValue = @{"Add" = @{"Ids" = @($members.Id); "IsAllSelected" = $false; "Search" = ""}}
        $response = $this.Update($payload)
        $group.SetDirty($true)
        return $response 
    }

    [Hashtable] GetPayloadBody()
    {
        return @{
            "Path" = @{
                "ObjectId" = ""
                "PropertyPath" = @()
            }
            "PropertyValue" = @{}
        }
    }
    
    <#[PSObject] QueryAllMembers($group){
        $State =  @{"Start" = 0; "SortBy" = $null; "Reverse" = $false; "Search" = $null}
        $Members = [System.Collections.ArrayList] @()
        while($State.start -lt $group.object.Members.count){
            $Members += ($this.QueryMembers($group, $state)).Item.Members.selected
            $State.start += $group.object.Members.itemsByPage
        }
        return $Members
    }

    [PSObject] QueryAllPossibleValues($group){
        $State =  @{"Start" = 0; "SortBy" = $null; "Reverse" = $false; "Search" = $null}
        $PossibleValues = [System.Collections.ArrayList] @()
        Do{
            $response = $this.QueryPossibleValues($group, $state)
            $PossibleValues += $response.PossibleValues
            $State.start += $group.object.Members.itemsByPage
        }while( $State.start -lt $response.count )
        return $PossibleValues
    }#>


}
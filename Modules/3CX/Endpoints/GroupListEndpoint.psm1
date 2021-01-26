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
                "ObjectId" = $group.GetEditID()
                "PropertyPath" = @(@{"Name" = "Members"})
            }
            "State" = $state
            "Count" = "100" # Incrases number of results returned per query
        }
        $PossibleValues = [System.Collections.ArrayList] @()

        #Cycle through pagination
        Do{
            $response = $this.ReadProperty($payload)
            $PossibleValues += $response.PossibleValues
            $State.start += $payload.Count
        }while( $State.start -lt $response.count )
        return $PossibleValues
    }

    [PSObject] QueryMembers( $group, $state )
    {
        $payload = @{
            "Path" = @{
                "ObjectId" = $group.GetEditID()
                "PropertyPath" = @(@{"Name" = "Members"})
            }
            "PropertyValue" = @{"State" = $state}
        }
        $Members = [System.Collections.ArrayList] @()
        Do{
            $response = $this.Update($payload)
            $Members += ($response | Select-Object -ExpandProperty Item).Members.Selected
            $State.start += $group.object.Members.itemsByPage
        }while( $State.start -lt $group.object.Members.count )
        
        return $Members
    }

}
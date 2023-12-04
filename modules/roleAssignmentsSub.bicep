targetScope = 'subscription'

param principalId string

var subReaderId = subscriptionResourceId('microsoft.authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

resource subReaderRa 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, subReaderId)
  properties: {
    roleDefinitionId: subReaderId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

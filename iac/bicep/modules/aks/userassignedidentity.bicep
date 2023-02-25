@description('A UNIQUE name')
@maxLength(23)
param appName string = 'petcliaks${uniqueString(resourceGroup().id, subscription().id)}'

param location string = resourceGroup().location


resource azidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'id-${appName}'
  location: location
}

output identityid string = azidentity.id
output clientId string = azidentity.properties.clientId
output principalId string = azidentity.properties.principalId

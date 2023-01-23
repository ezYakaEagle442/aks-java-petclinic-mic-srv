// https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

@description('The Identity location')
param location string = resourceGroup().location

@description('The Identity Tags. See https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=bicep#apply-an-object')
param tags object = {
  'Environment': 'Dev'
  'Dept': 'IT'
  'Scope': 'EU'
  'CostCenter': '442'
  'Owner': 'Petclinic'
}

///////////////////////////////////
// Resource names

// id-<app or service name>-<environment>-<region name>-<###>
// ex: id-appcn-keda-prod-eastus2-001

@description('AKS Cluster UserAssigned Managed Identity name. Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param aksIdentityName string = 'id-aks-cluster-dev-westeurope-101'

@description('The admin-server Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param adminServerAppIdentityName string = 'id-aks-petclinic-admin-server-dev-westeurope-101'

@description('The config-server Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param configServerAppIdentityName string = 'id-aks-petclinic-config-server-dev-westeurope-101'

@description('The discovery-server Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param discoveryServerAppIdentityName string = 'id-aks-petclinic-discovery-server-dev-westeurope-101'

@description('The api-gateway Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param apiGatewayAppIdentityName string = 'id-aks-petclinic-api-gateway-dev-westeurope-101'

@description('The customers-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param customersServiceAppIdentityName string = 'id-aks-petclinic-customers-service-dev-westeurope-101'

@description('The vets-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param vetsServiceAppIdentityName string = 'id-aks-petclinic-vets-service-dev-westeurope-101'

@description('The visits-service Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param visitsServiceAppIdentityName string = 'id-aks-petclinic-visits-service-dev-westeurope-101'

///////////////////////////////////
// New resources

// https://learn.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities?pivots=deployment-language-bicep
resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: aksIdentityName
  location: location
  tags: tags
}
output aksIdentityIdentityId string = aksIdentity.id
output aksIdentityPrincipalId string = aksIdentity.properties.principalId
output aksIdentityClientId string = aksIdentity.properties.clientId

resource adminServerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: adminServerAppIdentityName
  location: location
  tags: tags
}
output adminServerIdentityId string = adminServerIdentity.id
output adminServerPrincipalId string = adminServerIdentity.properties.principalId
output adminServerClientId string = adminServerIdentity.properties.clientId

resource configServerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: configServerAppIdentityName
  location: location
  tags: tags
}
output configServerIdentityId string = configServerIdentity.id
output configServerPrincipalId string = configServerIdentity.properties.principalId
output configServerClientId string = configServerIdentity.properties.clientId


resource discoveryServerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: discoveryServerAppIdentityName
  location: location
  tags: tags
}
output discoveryServerIdentityId string = discoveryServerIdentity.id
output discoveryServerPrincipalId string = discoveryServerIdentity.properties.principalId
output discoveryServerClientId string = discoveryServerIdentity.properties.clientId

resource apiGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: apiGatewayAppIdentityName
  location: location
  tags: tags
}
output apiGatewayIdentityId string = apiGatewayIdentity.id
output apiGatewayPrincipalId string = apiGatewayIdentity.properties.principalId
output apiGatewayClientId string = apiGatewayIdentity.properties.clientId

resource customersServicedentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: customersServiceAppIdentityName
  location: location
  tags: tags
}
output customersServiceIdentityId string = customersServicedentity.id
output customersServicePrincipalId string = customersServicedentity.properties.principalId
output customersServiceClientId string = customersServicedentity.properties.clientId

resource vetsServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: vetsServiceAppIdentityName
  location: location
  tags: tags
}
output vetsServiceIdentityId string = vetsServiceIdentity.id
output vetsServicePrincipalId string = vetsServiceIdentity.properties.principalId
output vetsServiceClientId string = vetsServiceIdentity.properties.clientId

resource visitsServiceIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: visitsServiceAppIdentityName
  location: location
  tags: tags
}
output visitsServiceIdentityId string = visitsServiceIdentity.id
output visitsServicePrincipalId string = visitsServiceIdentity.properties.principalId
output visitsServiceClientId string = visitsServiceIdentity.properties.clientId

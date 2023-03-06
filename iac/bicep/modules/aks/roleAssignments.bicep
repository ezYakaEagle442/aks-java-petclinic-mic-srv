@description('A UNIQUE name')
@maxLength(21)
param appName string = 'petcliaks${uniqueString(resourceGroup().id, subscription().id)}'

@description('The name of the ACR, must be UNIQUE. The name must contain only alphanumeric characters, be globally unique, and between 5 and 50 characters in length.')
param acrName string = 'acr${appName}'

param aksClusterPrincipalId string

@allowed([
  'Owner'
  'Contributor'
  'NetworkContributor'
  'Reader'
])
@description('VNet Built-in role to assign')
param networkRoleType string

@allowed([
  'AcrPull'
  'AcrPush'
])
@description('ACR Built-in role to assign')
param acrRoleType string = 'AcrPull'

@allowed([
  'KeyVaultAdministrator'
  'KeyVaultReader'
  'KeyVaultSecretsUser'  
])
@description('KV Built-in role to assign')
param kvRoleType string

param vnetName string
param subnetName string
param kvName string

@description('The name of the KV RG')
param kvRGName string

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' existing = {
  name: '${vnetName}/${subnetName}'
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: acrName
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: resourceGroup(kvRGName)
}

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var role = {
  Owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
  NetworkContributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
  AcrPull: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
  KeyVaultAdministrator: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483'
  KeyVaultReader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/21090545-7ca7-4776-b22c-e363652d74d2'
  KeyVaultSecretsUser: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'
}

// You need Key Vault Administrator permission to be able to see the Keys/Secrets/Certificates in the Azure Portal
/*
resource KVAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, kvRoleType , subscription().subscriptionId)
  scope: kv
  properties: {
    roleDefinitionId: role[kvRoleType]
    principalId: aksClusterPrincipalId
    principalType: 'ServicePrincipal'
  }
}
output kvAdminRoleAssignmentUpdatedOn string = KVAdminRoleAssignment.properties.updatedOn
output kvAdminRoleAssignmentId string = KVAdminRoleAssignment.id
output kvAdminRoleAssignmentName string = KVAdminRoleAssignment.name
*/

// https://github.com/Azure/azure-quickstart-templates/blob/master/modules/Microsoft.ManagedIdentity/user-assigned-identity-role-assignment/1.0/main.bicep
// https://github.com/Azure/bicep/discussions/5276
// Assign ManagedIdentity ID to the "Network contributor" role to AKS VNet
resource AKSClusterRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksSubnet.id, networkRoleType , aksClusterPrincipalId)
  scope: aksSubnet
  properties: {
    roleDefinitionId: role[networkRoleType] // subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: aksClusterPrincipalId
    principalType: 'ServicePrincipal'
  }
}

 // acrpull role to assign to the AKS identity: az role assignment create --assignee $sp_id --role acrpull --scope $acr_registry_id
 // /!\ This will be implemented later on through ACR Attachment to AKS using AKS Cluster Kubelet Identity
 // see ../../../../../.github/workflows/deploy-iac.yml
 /*
resource ACRRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, acrRoleType , aksClusterPrincipalId)
  scope: acr
  properties: {
    roleDefinitionId: role[acrRoleType]
    principalId: aksClusterPrincipalId
    principalType: 'ServicePrincipal'
  }
}
*/

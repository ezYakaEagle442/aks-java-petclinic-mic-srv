@description('A UNIQUE name')
@maxLength(21)
param appName string = 'petcli${uniqueString(resourceGroup().id, subscription().id)}'

// https://docs.microsoft.com/en-us/rest/api/containerregistry/registries/check-name-availability
@description('The name of the ACR, must be UNIQUE. The name must contain only alphanumeric characters, be globally unique, and between 5 and 50 characters in length.')
param acrName string = 'acr${appName}'

@description('The ACR location')
param location string = resourceGroup().location

// Specifies the IP or IP range in CIDR format. Only IPV4 address is allowed
@description('The AKS cluster CIDR')
param networkRuleSetCidr string = '172.16.0.0/16'


resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: false
    dataEndpointEnabled: false // data endpoint rule is not supported for the SKU Basic
  
    // VNet rule is not supported for the SKU Basic
    /*
    networkRuleSet: {
      defaultAction: 'Deny'
      
      ipRules: [
        {
          action: 'Allow'
          value: [] //  https://learn.microsoft.com/en-us/azure/container-registry/container-registry-access-selected-networks#access-from-aks
        }
      ]
      
    }*/
    //networkRuleBypassOptions: 'AzureServices'
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

output acrId string = acr.id
output acrName string = acr.name
output acrIdentity string = acr.identity.principalId
output acrType string = acr.type
output acrRegistryUrl string = acr.properties.loginServer

// outputs-should-not-contain-secrets
// output acrRegistryUsr string = acr.listCredentials().username
//output acrRegistryPwd string = acr.listCredentials().passwords[0].value

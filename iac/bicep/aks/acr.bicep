@description('A UNIQUE name')
@maxLength(20)
param appName string = '101-${uniqueString(deployment().name)}'

// https://docs.microsoft.com/en-us/rest/api/containerregistry/registries/check-name-availability
@description('The name of the ACR, must be UNIQUE. The name must contain only alphanumeric characters, be globally unique, and between 5 and 50 characters in length.')
param acrName string = 'acr-${appName}'

@description('The ACR location')
param location string = resourceGroup().location

// Specifies the IP or IP range in CIDR format. Only IPV4 address is allowed
@description('The AKS cluster CIDR')
param networkRuleSetCidr string


resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  /*
  identity: {
    principalId: 'string'
    tenantId: 'string'
    type: 'string'
    userAssignedIdentities: {}
  }
  */
  properties: {
    adminUserEnabled: false
    dataEndpointEnabled: false // data endpoint rule is not supported for the SKU Basic
    /*
    networkRuleSet: {
      defaultAction: 'Deny'
      ipRules: [
        {
          action: 'Allow'
          value: networkRuleSetCidr // []
        }
      ]
    }
    */
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

output acrId string = acr.id
// output acrIdentity string = acr.identity.principalId

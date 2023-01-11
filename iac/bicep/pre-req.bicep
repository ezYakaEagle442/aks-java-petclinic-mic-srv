// Check the REST API : https://learn.microsoft.com/en-us/rest/api/aks/managed-clusters

@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'petcliaks${uniqueString(resourceGroup().id)}'
param location string = 'westeurope'
param acrName string = 'acr${appName}'

@description('The Log Analytics workspace name used by the AKS cluster')
param logAnalyticsWorkspaceName string = 'log-${appName}'

@allowed([
  'log-analytics'
])
param logDestination string = 'log-analytics'

param appInsightsName string = 'appi-${appName}'

@description('Should the service be deployed to a Corporate VNet ?')
param deployToVNet bool = false

param vnetName string = 'vnet-aks'
param vnetCidr string = '172.16.0.0/16'
param aksSubnetCidr string = '172.16.1.0/24'
param aksSubnetName string = 'snet-aks'

@description('The MySQL DB Admin Login.')
param mySQLadministratorLogin string = 'mys_adm'

@secure()
@description('The MySQL DB Admin Password.')
param mySQLadministratorLoginPassword string

@description('The MySQL server name')
param mySQLServerName string = 'petcliaks'

@description('Should a MySQL Firewall be set to allow client workstation for local Dev/Test only')
param setFwRuleClient bool = false

@description('Allow client workstation IP adress for local Dev/Test only, requires setFwRuleClient=true')
param clientIPAddress string

@description('Allow AKS subnet to access MySQL DB')
param startIpAddress string

@description('Allow AKS subnet to access MySQL DB')
param endIpAddress string

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

@maxLength(24)
@description('The name of the KV, must be UNIQUE. A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

@description('AKS Cluster UserAssigned Managed Identity name. Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param aksIdentityName string = 'id-aks-cluster-dev-westeurope-101'

param dnsZone string = 'cloudapp.azure.com'
param appDnsZone string = 'kissmyapp.${location}.${dnsZone}'
param customDns string = 'javaonazurehandsonlabs.com'
param privateDnsZone string = 'privatelink.${location}.azmk8s.io'

// https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?tabs=bicep
resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

// https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/components?tabs=bicep
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    //Flow_Type: 'Bluefield'    
    //ImmediatePurgeDataOn30Days: true // "ImmediatePurgeDataOn30Days cannot be set on current api-version"
    //RetentionInDays: 30
    IngestionMode: 'LogAnalytics' // Cannot set ApplicationInsightsWithDiagnosticSettings as IngestionMode on consolidated application 
    Request_Source: 'rest'
    SamplingPercentage: 20
    WorkspaceResourceId: logAnalyticsWorkspace.id    
  }
}
output appInsightsId string = appInsights.id
output appInsightsConnectionString string = appInsights.properties.ConnectionString
// output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey

module ACR './modules/aks/acr.bicep' = {
  name: acrName
  params: {
    appName: appName
    acrName: acrName
    location: location
    networkRuleSetCidr: vnetCidr
  }
}

resource kvRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: kvRGName
  scope: subscription()
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: kvRG
}

module identities './modules/aks/identity.bicep' = {
  name: 'aks-identities'
  params: {
    location: location
  }
}

resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: aksIdentityName
}

module vnet './modules/aks/vnet.bicep' = {
  name: 'vnet-aks'
  // scope: resourceGroup(rg.name)
  params: {
    location: location
     vnetName: vnetName
     aksSubnetName: aksSubnetName
     vnetCidr: vnetCidr
     aksSubnetCidr: aksSubnetCidr
  }   
}

var vNetRules = [
  {
    'id': vnet.outputs.aksSubnetId
    'ignoreMissingVnetServiceEndpoint': false
  }
]

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scope-extension-resources
module roleAssignments './modules/aks/roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    acrName: acrName
    acrRoleType: 'AcrPull'
    aksVetsServicePrincipalId: identities.outputs.vetsServicePrincipalId
    aksVisitsServicePrincipalId: identities.outputs.visitsServicePrincipalId
    aksConfigServerPrincipalId: identities.outputs.configServerPrincipalId
    aksCustomersServicePrincipalId: identities.outputs.customersServicePrincipalId
    aksClusterPrincipalId: aksIdentity.properties.principalId
    kvName: kvName
    kvRGName: kvRGName
    kvRoleType: 'KeyVaultSecretsUser'
    networkRoleType: 'NetworkContributor'
    vnetName: vnetName
    subnetName: aksSubnetName
  }
}

module mysql './modules/mysql/mysql.bicep' = {
  name: 'mysqldb'
  params: {
    appName: appName
    location: location
    mySQLadministratorLogin: mySQLadministratorLogin
    mySQLadministratorLoginPassword: mySQLadministratorLoginPassword
    // The default number of managed outbound public IPs is 1.
    // https://learn.microsoft.com/en-us/azure/aks/load-balancer-standard#scale-the-number-of-managed-outbound-public-ips
    mySQLServerName: mySQLServerName
    setFwRuleClient: setFwRuleClient
    clientIPAddress: clientIPAddress
    startIpAddress: startIpAddress
    endIpAddress: endIpAddress
  }
}

/*
module DNS './modules/aks/dns.bicep' = {
  name: acrName
  params: {
    location: location
    vnetName: vnetName
    dnsZone: dnsZone
    privateDnsZone: privateDnsZone
    appDnsZone: appDnsZone
    customDns: customDns
    aksIp: 
  }
}
*/
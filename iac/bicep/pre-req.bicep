// Check the REST API : https://learn.microsoft.com/en-us/rest/api/aks/managed-clusters

@maxLength(21)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'petcli${uniqueString(resourceGroup().id, subscription().id)}'
param location string = resourceGroup().location
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


// https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-deploy-on-azure-free-account
@description('Azure Database for MySQL SKU')
@allowed([
  'Standard_D4s_v3'
  'Standard_D2s_v3'
  'Standard_B1ms'
])
param databaseSkuName string = 'Standard_B1ms' //  'GP_Gen5_2' for single server

@description('Azure Database for MySQL pricing tier')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param databaseSkuTier string = 'Burstable'

@description('MySQL version see https://learn.microsoft.com/en-us/azure/mysql/concepts-version-policy')
@allowed([
  '8.0.21'
  '8.0.28'
  '5.7'
])
param mySqlVersion string = '5.7' // https://docs.microsoft.com/en-us/azure/mysql/concepts-supported-versions

@description('The MySQL DB Admin Login.')
param mySQLadministratorLogin string = 'mys_adm'

@secure()
@description('The MySQL DB Admin Password.')
param mySQLadministratorLoginPassword string

@description('The MySQL server name')
param mySQLServerName string = appName

@description('The MySQL DB name.')
param dbName string = 'petclinic'

param charset string = 'utf8'

@allowed( [
  'utf8_general_ci'

])
param collation string = 'utf8_general_ci' // SELECT @@character_set_database, @@collation_database;

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

@maxLength(24)
@description('The name of the KV, must be UNIQUE. A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

@description('AKS Cluster UserAssigned Managed Identity name. Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param aksIdentityName string = 'id-aks-${appName}-cluster-dev-${location}-101'

@description('The Storage Account name')
param azureStorageName string = 'sta${appName}'

@description('The BLOB Storage service name')
param azureBlobServiceName string = 'default'

@description('The BLOB Storage Container name')
param blobContainerName string = '${appName}-blob'

@description('The GitHub Runner Service Principal Id')
param ghRunnerSpnPrincipalId string

param dnsZone string = 'cloudapp.azure.com'
param appDnsZone string = 'petclinic.${location}.${dnsZone}'
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
  name: 'acr'
  params: {
    appName: appName
    acrName: acrName
    location: location
    networkRuleSetCidr: vnetCidr
  }
}

output acrId string = ACR.outputs.acrId
output acrName string = ACR.outputs.acrName
output acrIdentity string = ACR.outputs.acrIdentity
output acrType string = ACR.outputs.acrType
output acrRegistryUrl string = ACR.outputs.acrRegistryUrl

resource kvRG 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: 'kv-rg'
  scope: subscription()
}

resource kv 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: 'kv'
  scope: kvRG
}

module identities './modules/aks/identity.bicep' = {
  name: 'aks-identities'
  params: {
    location: location
    appName: appName
    aksIdentityName: aksIdentityName
  }
}

output adminServerIdentityId string = identities.outputs.adminServerIdentityId
output adminServerPrincipalId string = identities.outputs.adminServerPrincipalId
output adminServerClientId string = identities.outputs.adminServerClientId

output configServerIdentityId string = identities.outputs.configServerIdentityId
output configServerPrincipalId string = identities.outputs.configServerPrincipalId
output configServerClientId string = identities.outputs.configServerClientId

output apiGatewayIdentityId string = identities.outputs.apiGatewayIdentityId
output apiGatewayPrincipalId string = identities.outputs.apiGatewayPrincipalId
output apiGatewayClientId string = identities.outputs.apiGatewayClientId

output customersServiceIdentityId string = identities.outputs.customersServiceIdentityId
output customersServicePrincipalId string = identities.outputs.customersServicePrincipalId
output customersServiceClientId string = identities.outputs.customersServiceClientId

output vetsServiceIdentityId string = identities.outputs.vetsServiceIdentityId
output vetsServicePrincipalId string = identities.outputs.vetsServicePrincipalId
output vetsServiceClientId string = identities.outputs.vetsServiceClientId

output visitsServiceIdentityId string = identities.outputs.visitsServiceIdentityId
output visitsServicePrincipalId string = identities.outputs.visitsServicePrincipalId
output visitsServiceClientId string = identities.outputs.visitsServiceClientId

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

output vnetId string = vnet.outputs.vnetId
output aksSubnetId string = vnet.outputs.aksSubnetId
output aksSubnetAddressPrefix string = vnet.outputs.aksSubnetAddressPrefix

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
    appName: appName
    acrName: acrName
    acrRoleType: 'AcrPull'
    aksClusterPrincipalId: identities.outputs.aksIdentityPrincipalId
    kvName: kvName
    kvRGName: kvRGName
    kvRoleType: 'KeyVaultSecretsUser'
    networkRoleType: 'NetworkContributor'
    storageBlobRoleType: 'StorageBlobDataContributor'
    ghRunnerSpnPrincipalId: ghRunnerSpnPrincipalId
    vnetName: vnetName
    subnetName: aksSubnetName
  }
  dependsOn: [
    ACR
  ]
}

module mysql './modules/mysql/mysql.bicep' = {
  name: 'mysqldb'
  params: {
    appName: appName
    location: location
    databaseSkuName: databaseSkuName
    databaseSkuTier: databaseSkuTier
    mySqlVersion: mySqlVersion
    mySQLServerName: mySQLServerName
    dbName: dbName
    mySQLadministratorLogin: mySQLadministratorLogin
    mySQLadministratorLoginPassword: mySQLadministratorLoginPassword
    // The default number of managed outbound public IPs is 1.
    // https://learn.microsoft.com/en-us/azure/aks/load-balancer-standard#scale-the-number-of-managed-outbound-public-ips
    charset: charset
    collation: collation

  }
}

output mySQLServerID string = mysql.outputs.mySQLServerID
output mySQLServerName string = mysql.outputs.mySQLServerName
output mySQLServerFQDN string = mysql.outputs.mySQLServerFQDN
output mySQLServerAdminLogin string = mysql.outputs.mySQLServerAdminLogin

output mysqlDBResourceId string = mysql.outputs.mysqlDBResourceId
output mysqlDBName string = mysql.outputs.mysqlDBName

module storage './modules/aks/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    appName: appName
    blobContainerName: blobContainerName
    azureBlobServiceName: azureBlobServiceName
    azureStorageName: azureStorageName
  }
  dependsOn: [
    identities
  ] 
}

output azurestorageId string = storage.outputs.azurestorageId
output azurestorageName string =storage.outputs.azurestorageName
output azurestorageHttpEndpoint string = storage.outputs.azurestorageHttpEndpoint
output azurestorageFileEndpoint string = storage.outputs.azurestorageFileEndpoint

output azureblobserviceId string = storage.outputs.azureblobserviceId
output azureblobserviceName string = storage.outputs.azureblobserviceName

output blobcontainerId string = storage.outputs.blobcontainerId
output blobcontainerName string = storage.outputs.blobcontainerName

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

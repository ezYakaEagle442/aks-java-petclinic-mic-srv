@maxLength(21)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'petcli${uniqueString(resourceGroup().id, subscription().id)}'
param location string = resourceGroup().location

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

@maxLength(24)
@description('The name of the KV, must be UNIQUE. A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

@description('The VNet rules to whitelist for the KV')
param  vNetRules array = []
@description('The IP rules to whitelist for the KV & MySQL')
param  ipRules array = []

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

@description('The MySQL server name')
param mySQLServerName string = appName

@description('The MySQL DB name.')
param dbName string = 'petclinic'

param charset string = 'utf8'

@allowed( [
  'utf8_general_ci'

])
param collation string = 'utf8_general_ci' // SELECT @@character_set_database, @@collation_database;


resource kvRG 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: kvRGName
  scope: subscription()
}


// see https://github.com/microsoft/azure-container-apps/issues/469
// Now KV must Allow AKS OutboundPubIP in the IP rules ...
// Must allow AKS to access Existing KV

module kvsetiprules './modules/kv/kv.bicep' = {
  name: 'kv-set-iprules'
  scope: kvRG
  params: {
    kvName: kvName
    location: location
    ipRules: ipRules
    vNetRules: vNetRules
  }
}

output keyVault object = kvsetiprules.outputs.keyVault
output keyVaultId string = kvsetiprules.outputs.keyVaultId
output keyVaultName string = kvsetiprules.outputs.keyVaultName
output keyVaultURI string = kvsetiprules.outputs.keyVaultURI
output keyVaultPublicNetworkAccess string = kvsetiprules.outputs.keyVaultPublicNetworkAccess
output keyVaultPublicNetworkAclsIpRules array = kvsetiprules.outputs.keyVaultPublicNetworkAclsIpRules

resource kv 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: kvName
  scope: kvRG
}  

module mysqlPub './modules/mysql/mysql.bicep' = {
  name: 'mysqldbpub'
  params: {
    appName: appName
    location: location
    mySQLServerName: mySQLServerName
    dbName: dbName
    databaseSkuName: databaseSkuName
    databaseSkuTier: databaseSkuTier
    mySqlVersion: mySqlVersion
    mySQLadministratorLogin: mySQLadministratorLogin
    mySQLadministratorLoginPassword: kv.getSecret('SPRING-DATASOURCE-PASSWORD')
    k8sOutboundPubIP: ipRules[0]
    charset: charset
    collation: collation

  }
}

output mySQLServerID string = mysqlPub.outputs.mySQLServerID
output mySQLServerName string = mysqlPub.outputs.mySQLServerName
output mySQLServerFQDN string = mysqlPub.outputs.mySQLServerFQDN
output mySQLServerAdminLogin string = mysqlPub.outputs.mySQLServerAdminLogin

output mysqlDBResourceId string = mysqlPub.outputs.mysqlDBResourceId
output mysqlDBName string = mysqlPub.outputs.mysqlDBName

output fwRuleResourceId string = mysqlPub.outputs.fwRuleResourceId
output fwRuleName string = mysqlPub.outputs.fwRuleName

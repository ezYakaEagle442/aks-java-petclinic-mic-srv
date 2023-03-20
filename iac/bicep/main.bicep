
@maxLength(21)
param appName string = 'petcli${uniqueString(resourceGroup().id, subscription().id)}'

param location string = resourceGroup().location
// param rgName string = 'rg-${appName}'
param dnsPrefix string = 'appinnojava'
param acrName string = 'acr${appName}'
param clusterName string = 'aks-${appName}'
param aksVersion string = '1.24.6'
param MCnodeRG string = 'rg-MC-${appName}'
param logAnalyticsWorkspaceName string = 'log-${appName}'
param vnetName string = 'vnet-aks'

@description('AKS Cluster UserAssigned Managed Identity name. Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param aksIdentityName string = 'id-aks-${appName}-cluster-dev-${location}-101'

@description('The AKS SSH public key')
@secure()
param sshPublicKey string

@description('IP ranges string Array allowed to call the AKS API server, specified in CIDR format, e.g. 137.117.106.88/29. see https://learn.microsoft.com/en-us/azure/aks/api-server-authorized-ip-ranges')
param authorizedIPRanges array = []
  
@description('The AKS Cluster Admin Username')
param aksAdminUserName string = 'aks-admin'

@maxLength(24)
@description('The name of the KV, must be UNIQUE.  A vault name must be between 3-24 alphanumeric characters.')
param kvName string ='kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

@description('Is KV Network access public ?')
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'

@description('The KV SKU name')
@allowed([
  'premium'
  'standard'
])
param skuName string = 'standard'

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

param dnsZone string = 'cloudapp.azure.com'
param appDnsZone string = 'petclinic.${location}.${dnsZone}'
param customDns string = 'javaonazurehandsonlabs.com'
param privateDnsZone string = 'privatelink.${location}.azmk8s.io'

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/key-vault-parameter?tabs=azure-cli
/*
The user who deploys the Bicep file must have the Microsoft.KeyVault/vaults/deploy/action permission for the scope 
of the resource group and key vault. 
The Owner and Contributor roles both grant this access.
If you created the key vault, you're the owner and have the permission.
*/

resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' existing= {
  name: vnetName
}

// https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep
// https://mcr.microsoft.com/v2/azure-cli/tags/list
// https://mcr.microsoft.com/v2/azuredeploymentscripts-powershell/tags/list
resource passwordgenerator 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'pass-gen'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '9.4' // or azCliVersion: '2.45.0'
    retentionInterval: 'P1D'
    scriptContent: loadTextContent('./passwordgenerator.ps1')
  }
}

//output encodedPassword string =  passwordgenerator.properties.outputs.encodedPassword
//output passwordText string =  passwordgenerator.properties.outputs.password

module prereq './pre-req.bicep' = {
  name: 'pre-req'
  params: {
    appName: appName
    location: location
    acrName: acrName
    kvName: kvName
    kvRGName: kvRGName
    ghRunnerSpnPrincipalId: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    customDns: appDnsZone
    mySQLadministratorLoginPassword: passwordgenerator.properties.outputs.password
  }
}


output aksIdentityIdentityId string = prereq.outputs.aksIdentityIdentityId
output aksIdentityClientId string = prereq.outputs.aksIdentityClientId
output aksIdentityPrincipalId string = prereq.outputs.aksIdentityPrincipalId
output aksIdentityName string = prereq.outputs.aksIdentityName

output adminServerIdentityId string = prereq.outputs.adminServerIdentityId
output adminServerPrincipalId string = prereq.outputs.adminServerPrincipalId
output adminServerClientId string = prereq.outputs.adminServerClientId

output configServerIdentityId string = prereq.outputs.configServerIdentityId
output configServerPrincipalId string = prereq.outputs.configServerPrincipalId
output configServerClientId string = prereq.outputs.configServerClientId

output apiGatewayIdentityId string = prereq.outputs.apiGatewayIdentityId
output apiGatewayPrincipalId string = prereq.outputs.apiGatewayPrincipalId
output apiGatewayClientId string = prereq.outputs.apiGatewayClientId

output customersServiceIdentityId string = prereq.outputs.customersServiceIdentityId
output customersServicePrincipalId string = prereq.outputs.customersServicePrincipalId
output customersServiceClientId string = prereq.outputs.customersServiceClientId

output vetsServiceIdentityId string = prereq.outputs.vetsServiceIdentityId
output vetsServicePrincipalId string = prereq.outputs.vetsServicePrincipalId
output vetsServiceClientId string = prereq.outputs.vetsServiceClientId

output visitsServiceIdentityId string = prereq.outputs.visitsServiceIdentityId
output visitsServicePrincipalId string = prereq.outputs.visitsServicePrincipalId
output visitsServiceClientId string = prereq.outputs.visitsServiceClientId

output vnetId string = prereq.outputs.vnetId
output aksSubnetId string = prereq.outputs.aksSubnetId

output acrId string = prereq.outputs.acrId
output acrName string = prereq.outputs.acrName
output acrType string = prereq.outputs.acrType
output acrRegistryUrl string = prereq.outputs.acrRegistryUrl

output logAnalyticsWorkspaceName string = prereq.outputs.logAnalyticsWorkspaceName
output logAnalyticsWorkspaceResourceId string = prereq.outputs.logAnalyticsWorkspaceResourceId
output logAnalyticsWorkspaceCustomerId string = prereq.outputs.logAnalyticsWorkspaceCustomerId

output appInsightsName string = prereq.outputs.appInsightsName
output appInsightsConnectionString string = prereq.outputs.appInsightsConnectionString

output mySQLServerID string = prereq.outputs.mySQLServerID
output mySQLServerName string = prereq.outputs.mySQLServerName
output mySQLServerFQDN string = prereq.outputs.mySQLServerFQDN
output mySQLServerAdminLogin string = prereq.outputs.mySQLServerAdminLogin

output mysqlDBResourceId string = prereq.outputs.mysqlDBResourceId
output mysqlDBName string = prereq.outputs.mysqlDBName

output azurestorageId string = prereq.outputs.azurestorageId
output azurestorageName string =prereq.outputs.azurestorageName
output azurestorageHttpEndpoint string = prereq.outputs.azurestorageHttpEndpoint
output azurestorageFileEndpoint string = prereq.outputs.azurestorageFileEndpoint

output azureblobserviceId string = prereq.outputs.azureblobserviceId
output azureblobserviceName string = prereq.outputs.azureblobserviceName

output blobcontainerId string = prereq.outputs.blobcontainerId
output blobcontainerName string = prereq.outputs.blobcontainerName

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-secrets
module aks './modules/aks/aks.bicep' = {
  name: 'aks'
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    clusterName: clusterName
    k8sVersion: aksVersion
    location: location
    nodeRG:MCnodeRG
    subnetID: vnet.properties.subnets[0].id
    dnsPrefix: dnsPrefix
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    aksIdentityName: aksIdentityName
    sshPublicKey: sshPublicKey
    aksAdminUserName: aksAdminUserName
    kvName: kvName
    authorizedIPRanges: authorizedIPRanges
  }
  dependsOn: [
    prereq
  ]
}

// https://github.com/Azure/azure-rest-api-specs/issues/17563
output controlPlaneFQDN string = aks.outputs.controlPlaneFQDN
output kubeletIdentity string = aks.outputs.kubeletIdentity
output keyVaultAddOnIdentity string = aks.outputs.keyVaultAddOnIdentity
output spnClientId string = aks.outputs.spnClientId
output aksId string = aks.outputs.aksId
output aksClusterName string = aks.name
output aksOutboundType string = aks.outputs.aksOutboundType
// The default number of managed outbound public IPs is 1.
// https://learn.microsoft.com/en-us/azure/aks/load-balancer-standard#scale-the-number-of-managed-outbound-public-ips
output aksEffectiveOutboundIPs array = aks.outputs.aksEffectiveOutboundIPs
output aksManagedOutboundIPsCount int = aks.outputs.aksManagedOutboundIPsCount

resource kvRG 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: kvRGName
  scope: subscription()
}

resource kv 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: kvName
  scope: kvRG
}

module attachacr './modules/aks/attach-acr.bicep' = {
  name: 'attach-acr'
  params: {
    appName: appName
    acrName: prereq.outputs.acrName
    aksClusterPrincipalId: aks.outputs.kubeletIdentity
  }
  dependsOn: [
    aks
  ]
}


var vNetRules = [vnet.properties.subnets[0].id]
var aksOutboundIPResourceId = aks.outputs.aksEffectiveOutboundIPs

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: aksIdentityName
}

// https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep
// https://mcr.microsoft.com/v2/azure-cli/tags/list
// https://mcr.microsoft.com/v2/azuredeploymentscripts-powershell/tags/list
resource getAKSIPAddress 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'get-aks-ip-address'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  } 
  properties: {
    azCliVersion: '2.45.0'
    retentionInterval: 'P1D'
    arguments: '\\"${aksOutboundIPResourceId[0]}\\"'
    scriptContent: loadTextContent('./get-aks-ip-address.sh')
    cleanupPreference: 'OnSuccess'
  }
  dependsOn: [
    aks
  ]
}

output aksIpAddress object = getAKSIPAddress.properties.outputs
output aksIp string = getAKSIPAddress.properties.outputs.Result

var ipRules=[getAKSIPAddress.properties.outputs.Result]
module kvsetiprules './set-ip-rules.bicep' = {
  name: 'kv-set-iprules'
  scope: kvRG
  params: {
    appName: appName
    kvName: kvName
    kvRGName: kvRGName
    location: location
    ipRules: ipRules
    vNetRules: vNetRules
  }
  dependsOn: [
    aks
  ]  
}

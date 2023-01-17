@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'petclinic${uniqueString(resourceGroup().id)}'

param location string = 'westeurope'
// param rgName string = 'rg-${appName}'
param dnsPrefix string = 'appinnojava'
param acrName string = 'acr${appName}'
param clusterName string = 'aks-${appName}'
param aksVersion string = '1.24.6'
param MCnodeRG string = 'rg-MC-${appName}'
param logAnalyticsWorkspaceName string = 'log-${appName}'
param vnetName string = 'vnet-aks'
param subnetName string = 'snet-aks'
param vnetCidr string = '172.16.0.0/16'
param aksSubnetCidr string = '172.16.1.0/24'

@description('Allow AKS subnet to access MySQL DB')
param startIpAddress string = '172.16.1.0'

@description('Allow AKS subnet to access MySQL DB')
param endIpAddress string = '172.16.1.255'

@description('AKS Cluster UserAssigned Managed Identity name. Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param aksIdentityName string = 'id-aks-cluster-dev-westeurope-101'

@description('The AKS SSH public key')
@secure()
param sshPublicKey string

@description('IP ranges string Array allowed to call the AKS API server, specified in CIDR format, e.g. 137.117.106.88/29. see https://learn.microsoft.com/en-us/azure/aks/api-server-authorized-ip-ranges')
param authorizedIPRanges array = []
  
@description('The AKS Cluster Admin Username')
param aksAdminUserName string = '${appName}-admin'

@maxLength(24)
@description('The name of the KV, must be UNIQUE.  A vault name must be between 3-24 alphanumeric characters.')
param kvName string // = 'kv-${appName}'

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

@description('The MySQL DB Admin Login.')
param mySQLadministratorLogin string = 'mys_adm'

@secure()
@description('The MySQL DB Admin Password.')
param mySQLadministratorLoginPassword string

@description('The MySQL server name')
param mySQLServerName string = 'petcliaks'

@description('Allow client workstation to MySQL for local Dev/Test only')
param clientIPAddress string

@description('Should a MySQL Firewall be set to allow client workstation for local Dev/Test only')
param setFwRuleClient bool = false


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
}
output controlPlaneFQDN string = aks.outputs.controlPlaneFQDN
// https://github.com/Azure/azure-rest-api-specs/issues/17563
output kubeletIdentity string = aks.outputs.kubeletIdentity
output keyVaultAddOnIdentity string = aks.outputs.keyVaultAddOnIdentity
output spnClientId string = aks.outputs.spnClientId
output aksId string = aks.outputs.aksId
output aksOutboundType string = aks.outputs.aksOutboundType
// The default number of managed outbound public IPs is 1.
// https://learn.microsoft.com/en-us/azure/aks/load-balancer-standard#scale-the-number-of-managed-outbound-public-ips
output aksEffectiveOutboundIPs array = aks.outputs.aksEffectiveOutboundIPs
output aksManagedOutboundIPsCount int = aks.outputs.aksManagedOutboundIPsCount

resource kvRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: kvRGName
  scope: subscription()
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: kvRG
}

/*
var ipRules = aks.outputs.aksOutboundIPs[0]
var vNetRules = [vnet.properties.subnets[0].id]
module kvsetiprules './modules/kv/kv.bicep' = {
  name: 'kv-set-iprules'
  scope: kvRG
  params: {
    kvName: kvName
    location: location
    ipRules: ipRules
    vNetRules: vNetRules
  }
  dependsOn: [
    aks
  ]  
}
*/

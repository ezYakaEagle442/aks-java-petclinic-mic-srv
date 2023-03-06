/*
az deployment group create --name aks-petclinic-storage -f iac/bicep/modules/aks/storage.bicep -g ${{ env.RG_APP }} \
            -p appName=${{ env.APP_NAME }} \
            -p location=${{ env.LOCATION }}
            
*/
@description('A UNIQUE name')
@maxLength(21)
param appName string = 'petcli${uniqueString(resourceGroup().id, subscription().id)}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

@description('The name of the Managed Cluster resource.')
param clusterName string = 'aks-${appName}'

@description('The Azure Active Directory tenant ID that should be used to manage AKS cluster Identity.')
param tenantId string = subscription().tenantId

@description('The Storage Account name')
param azureStorageName string = 'staks${appName}'

@description('The BLOB Storage service name')
param azureBlobServiceName string = 'default' // '${appName}-blob-svc'

@description('The BLOB Storage Container name')
param blobContainerName string = '${appName}-blob'

@allowed([
  'StorageBlobDataContributor'
])
@description('Azure Blob Storage Built-in role to assign')
param storageBlobRoleType string = 'StorageBlobDataContributor'

param ghRunnerSpnPrincipalId string

@description('The VNet rules to whitelist for the Strorage Account')
param  vNetRules array = []

@description('The IP rules to whitelist for the Strorage Account')
param  ipRules array = []

@description('The Identity Tags. See https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=bicep#apply-an-object')
param tags object = {
  Environment: 'Dev'
  Dept: 'IT'
  Scope: 'EU'
  CostCenter: '442'
  Owner: 'Petclinic'
}

@description('The Azure Strorage Identity name, see Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param storageIdentityName string = 'id-aks-${appName}-petclinic-strorage-dev-${location}-101'


// https://learn.microsoft.com/en-us/azure/templates/microsoft.managedidentity/userassignedidentities?pivots=deployment-language-bicep
resource storageIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: storageIdentityName
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep
resource azurestorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: azureStorageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${storageIdentity.id}': {}
    }   
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowCrossTenantReplication: false
    allowedCopyScope: 'AAD'
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    // https://learn.microsoft.com/en-us/azure/storage/blobs/storage-feature-support-in-storage-accounts
    dnsEndpointType: 'Standard' // AzureDnsZone in Preview  https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/storage/common/storage-account-overview.md#azure-dns-zone-endpoints-preview
    // Immutability policies are not supported in accounts that have the Network File System (NFS) 3.0 protocol or the SSH File Transfer Protocol (SFTP) enabled on them. https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-policy-configure-version-scope?tabs=azure-portal
    /*immutableStorageWithVersioning: {
      enabled: false
      
      immutabilityPolicy: {
        allowProtectedAppendWrites: false
        immutabilityPeriodSinceCreationInDays: 5
        state: 'Disabled'
      }
    }*/
    isHnsEnabled: true
    isNfsV3Enabled: true
    keyPolicy: {
      keyExpirationPeriodInDays: 180
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules:  [for ipRule in ipRules: {
        action: 'Allow'
        value: ipRule
      }]
      virtualNetworkRules:  [for vNetId in vNetRules: {
        action: 'Allow'
        id: vNetId
      }]
      /*
      resourceAccessRules: [
        {
          resourceId: aks.id
          tenantId: tenantId
        }
      ]
      */
    }
    publicNetworkAccess: 'Enabled'
    routingPreference: {
      publishInternetEndpoints: true
      publishMicrosoftEndpoints: true
      routingChoice: 'MicrosoftRouting'
    }
    sasPolicy: {
      expirationAction: 'Log'
      sasExpirationPeriod: '30.23:59:00'
    }
    supportsHttpsTrafficOnly: true
  }
}

output azurestorageId string = azurestorage.id
output azurestorageName string = azurestorage.name
// outputs-should-not-contain-secrets
// output azurestorageSasToken string = azurestorage.listAccountSas().accountSasToken
// output azurestorageKey0 string = azurestorage.listKeys().keys[0].value
// output azurestorageKey1 string = azurestorage.listKeys().keys[1].value

output azurestorageHttpEndpoint string = azurestorage.properties.primaryEndpoints.blob
output azurestorageFileEndpoint string = azurestorage.properties.primaryEndpoints.file


resource azureblobservice 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: azureBlobServiceName
  parent: azurestorage
  properties: {
    containerDeleteRetentionPolicy: {
      allowPermanentDelete: true
      days: 5
      enabled: true
    }
    // defaultServiceVersion: ''
    deleteRetentionPolicy: {
      allowPermanentDelete: true
      days: 180
      enabled: true
    }
    isVersioningEnabled: false
    lastAccessTimeTrackingPolicy: {
      blobType: [
        'blockBlob'
      ]
      enable: false
      name: 'AccessTimeTracking'
      trackingGranularityInDays: 30
    }
    restorePolicy: {
      days: 30
      enabled: false
    }
  }
}
output azureblobserviceId string = azureblobservice.id
output azureblobserviceName string = azureblobservice.name

resource blobcontainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: blobContainerName
  parent: azureblobservice
  properties: {
    // defaultEncryptionScope: 'string'
    //denyEncryptionScopeOverride: true
    enableNfsV3AllSquash: false
    enableNfsV3RootSquash: false
    // Immutability policies are not supported in accounts that have the Network File System (NFS) 3.0 protocol or the SSH File Transfer Protocol (SFTP) enabled on them. https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-policy-configure-version-scope?tabs=azure-portal
    /*
    immutableStorageWithVersioning: {
      enabled: false
    }*/
    publicAccess: 'Container'
  }
}
output blobcontainerId string = blobcontainer.id
output blobcontainerName string = blobcontainer.name

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
  StorageBlobDataContributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

// GH Runner SPN must have "Storage Blob Data Contributor" Role on the storage Account
// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?pivots=deployment-language-bicep
resource StorageBlobDataContributorRoleAssignmentGHRunner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(azureblobservice.id, storageBlobRoleType , ghRunnerSpnPrincipalId)
  scope: azurestorage
  properties: {
    roleDefinitionId: role[storageBlobRoleType]
    principalId: ghRunnerSpnPrincipalId
    principalType: 'ServicePrincipal'
  }
}

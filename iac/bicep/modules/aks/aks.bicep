// see BICEP samples at https://github.com/ssarwa/Bicep/blob/master/main.bicep
// https://github.com/brwilkinson/AzureDeploymentFramework/blob/main/ADF/bicep/AKS.bicep
@description('A UNIQUE name')
@maxLength(20)
param appName string = '101-${uniqueString(deployment().name)}'

@description('The name of the Managed Cluster resource.')
param clusterName string = 'aks-${appName}'

@description('The AKS SSH public key')
@secure()
param sshPublicKey string

@description('IP ranges string Array allowed to call the AKS API server, specified in CIDR format, e.g. 137.117.106.88/29. see https://learn.microsoft.com/en-us/azure/aks/api-server-authorized-ip-ranges')
param authorizedIPRanges array = []
  
@description('The AKS Cluster Admin Username')
param aksAdminUserName string = '${appName}-admin'

// Preview: https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli#kubernetes-version-alias-preview
@description('The AKS Cluster alias version')
param k8sVersion string = '1.24.6' //1.25.2 Alias in Preview

@description('The SubnetID to deploy the AKS Cluster')
param subnetID string

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string = 'appinno'

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('AKS Cluster UserAssigned Managed Identity')
param aksIdentityName string = 'aks-${appName}-identity'

@description('The Log Analytics workspace used by the OMS agent in the AKS Cluster')
param logAnalyticsWorkspaceId string 

@description('The number of nodes for the cluster.')
@minValue(1)
@maxValue(12)
param agentCount int = 3

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_D2s_v3'

@description('The AKS cluster Managed ResourceGroup')
param nodeRG string = 'rg-MC-${appName}'

@maxLength(24)
@description('The name of the KV, must be UNIQUE.  A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

param logAnalyticsWorkspaceName string = 'log-${appName}'

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: kvName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.containerservice/managedclusters?tabs=bicep
// https://github.com/Azure/AKS-Construction/blob/main/bicep/main.bicep
resource aks 'Microsoft.ContainerService/managedClusters@2022-09-02-preview' = {
  name: clusterName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Free'
  }    
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: aksIdentityName
  } 
  properties: {
    dnsPrefix: dnsPrefix
    enableRBAC: true
    agentPoolProfiles: [
      {
        availabilityZones: [
          '1'
          '2'
          '3'
        ]        
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        enableAutoScaling: true
        count: agentCount
        minCount: 1        
        maxCount: 3
        maxPods: 30
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
        // spotMaxPrice: json('0.0229')
        vnetSubnetID: subnetID
        osSKU: 'CBLMariner'
      }  
    ]
    linuxProfile: {
      adminUsername: aksAdminUserName
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }
    }  
    storageProfile: {
      diskCSIDriver: {
        enabled: true
        version: 'V1'
      }
      fileCSIDriver: {
        enabled: true
      }
      snapshotController: {
        enabled: true
      }
      blobCSIDriver: {
        enabled: true
      }
    }    
    apiServerAccessProfile: !empty(authorizedIPRanges) ? {
      authorizedIPRanges: authorizedIPRanges
    } :{
      enablePrivateCluster: false
      privateDNSZone: ''
      enablePrivateClusterPublicFQDN: false     
      enableVnetIntegration: false
    }      
    // see https://github.com/Azure/azure-rest-api-specs/issues/17563
    // https://github.com/brwilkinson/AzureDeploymentFramework/blob/main/ADF/bicep/AKS.bicep (main)
    // https://github.com/brwilkinson/AzureDeploymentFramework/blob/main/ADF/bicep/AKS-AKS.bicep
    // https://github.com/brwilkinson/AzureDeploymentFramework/blob/main/ADF/tenants/AOA/ACU1.T5.parameters.json#L985
    // https://docs.microsoft.com/en-us/rest/api/aks/managed-clusters/create-or-update#managedclusteraddonprofile

    addonProfiles: {
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
        enabled: true
      }
      gitops: {
        enabled: true
        config: {          
        }
      }      
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      /*
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: appGatewayResourceId
          effectiveApplicationGatewayId: appGatewayResourceId
        }
      }
      */
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
        }        
      }
      openServiceMesh: {
        enabled: true
        config: {}
      }

    }
    azureMonitorProfile: {
      metrics: {
        enabled: true
        /*
        kubeStateMetrics: {
          metricAnnotationsAllowList: 'string'
          metricLabelsAllowlist: 'string'
        }*/
      }
    }    
    nodeResourceGroup: nodeRG    
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
    } 
    kubernetesVersion: k8sVersion  
    networkProfile: {
      networkMode: 'transparent'
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      outboundType: 'loadBalancer'
      serviceCidr: '10.42.0.0/24'
      dnsServiceIP: '10.42.0.10'         
    }           
  }
}

// https://github.com/Azure/azure-rest-api-specs/issues/17563
output controlPlaneFQDN string = aks.properties.fqdn
output kubeletIdentity string = aks.properties.identityProfile.kubeletidentity.objectId
output keyVaultAddOnIdentity string = aks.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId
output managedIdentityPrincipalId string = aks.properties.servicePrincipalProfile.clientId
// output ingressIdentity string = aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId


// https://learn.microsoft.com/en-us/azure/templates/microsoft.management/managementgroups?pivots=deployment-language-bicep
/*
resource managementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'managementGroup'
  scope: tenant()
  properties: {
    details: {
      parent: {
        id: managementGroupParentId
      }
    }
    displayName: managementGroupDisplayName
  }
}
*/

resource AKSDiags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'AKSDiags'
  scope: aks
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'kube-apiserver'
        enabled: true
      }
      {
        category: 'kube-audit'
        enabled: true
      }
      {
        category: 'kube-audit-admin'
        enabled: true
      }
      {
        category: 'kube-controller-manager'
        enabled: true
      }
      {
        category: 'kube-scheduler'
        enabled: false
      }
      {
        category: 'cluster-autoscaler'
        enabled: false
      }
      {
        category: 'guard'
        enabled: true
      }
    ]
    metrics: [
      {
        timeGrain: 'PT5M'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 7
        }
      }
    ]
  }
}

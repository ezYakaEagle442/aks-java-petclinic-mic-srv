/*
az deployment group create --name test-get-aks-ip -f ./iac/bicep/modules/test/getAKSIPAddress.bicep -g rg-iac-aks-petclinic-mic-srv \
-p location=westeurope -p appName=petcliaks
*/

param location string = resourceGroup().location// 'westeurope' 
param aksOutboundIPResourceId array // = ['/subscriptions/aab8ea14-55ea-4749-863d-50d13ff4e657/resourceGroups/rg-MC-petcliaks/providers/Microsoft.Network/publicIPAddresses/42ea70c9-491e-4caa-84b8-ba6c9e7e35ec']
// param tenantId string = subscription().tenantId

@maxLength(21)
param appName string = 'petcli${uniqueString(resourceGroup().id, subscription().id)}'

@description('AKS Cluster UserAssigned Managed Identity name. Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param aksIdentityName string = 'id-aks-${appName}-cluster-dev-${location}-101' // 'id-aks-petcliaks-cluster-dev-westeurope-101'

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
    //scriptContent: 'echo "arg1 is: $1"; echo "arg2 is: $2"; echo "arg3 is: $3"; echo "arg4 is: $4" ; result="{\\"foo\\":\\"toto\\"}" ; echo $result | jq -c \'{Result: \\"$1\\"}\' > $AZ_SCRIPTS_OUTPUT_PATH' // echo '{"foo": 0}' | jq .
    scriptContent: loadTextContent('../../get-aks-ip-address.sh')
    //scriptContent: 'echo "arg1 is: $1"; result=$(az network public-ip show --ids $1 --query ipAddress | tr -d "\\r\\n"); echo "{\\"Result\\":\\"$result\\"}" | jq . > $AZ_SCRIPTS_OUTPUT_PATH'
    //scriptContent: 'echo "arg1 is: $1"; az login -u $2 -p $3 --tenant $4; result=$(az network public-ip show --ids $1 --query ipAddress); echo $result > $AZ_SCRIPTS_OUTPUT_PATH'
    // :"The template output 'result' is not valid: The language expression property 'outputs' doesn't exist, available properties are 'provisioningState, azCliVersion, scriptContent, arguments, retentionInterval, timeout, containerSettings, status, cleanupPreference'.."}]}}
    cleanupPreference: 'OnSuccess'
  }
}

output aksIpAddress object = getAKSIPAddress.properties.outputs
output aksIp string = getAKSIPAddress.properties.outputs.Result

/*
az deployment group create --name test-pass-geb -f ./iac/bicep/modules/test/passwordgenerator.bicep -g rg-iac-aks-petclinic-mic-srv \
-p location=westeurope 
*/

param location string = 'westeurope' // resourceGroup().location

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
    scriptContent: loadTextContent('../../passwordgenerator.ps1')
  }
}

output encodedPassword string =  passwordgenerator.properties.outputs.encodedPassword
output passwordText string =  passwordgenerator.properties.outputs.password

@description('A UNIQUE name')
@maxLength(23)
param appName string = 'petcliaks${uniqueString(resourceGroup().id, subscription().id)}'

param logAnalyticsWorkspaceName string = 'log-${appName}'

@description('The location of the Azure resources.')
param location string = resourceGroup().location

// https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?tabs=bicep
resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name

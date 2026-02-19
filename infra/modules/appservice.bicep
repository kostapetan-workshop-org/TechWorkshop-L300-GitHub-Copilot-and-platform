@description('Name of the App Service')
param appServiceName string

@description('Name of the App Service Plan')
param appServicePlanName string

@description('Location for the resources')
param location string

@description('Tags to apply to the resources')
param tags object = {}

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Azure AI Services endpoint')
param aiEndpoint string = ''

@description('Azure AI deployment name')
param aiDeploymentName string = 'Phi-4'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceName
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'AzureAI__Endpoint'
          value: aiEndpoint
        }
        {
          name: 'AzureAI__DeploymentName'
          value: aiDeploymentName
        }
      ]
    }
    httpsOnly: true
  }
}

@description('The default hostname of the App Service')
output hostname string = appService.properties.defaultHostName

@description('The principal ID of the App Service managed identity')
output principalId string = appService.identity.principalId

@description('The resource ID of the App Service')
output id string = appService.id

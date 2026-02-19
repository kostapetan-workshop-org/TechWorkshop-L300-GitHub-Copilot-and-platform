targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (used to generate resource names)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the resource group')
param resourceGroupName string = ''

// Generate resource names based on environment
var abbrs = {
  resourceGroup: 'rg-'
  appServicePlan: 'plan-'
  appService: 'app-'
  containerRegistry: 'acr'
  logAnalytics: 'log-'
  appInsights: 'appi-'
  aiServices: 'ais-'
  aiHub: 'aihub-'
  aiProject: 'aiproj-'
}

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var rgName = !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourceGroup}${environmentName}'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
}

module monitoring 'modules/monitoring.bicep' = {
  scope: rg
  params: {
    logAnalyticsName: '${abbrs.logAnalytics}${resourceToken}'
    appInsightsName: '${abbrs.appInsights}${resourceToken}'
    location: location
    tags: {
      'azd-env-name': environmentName
    }
  }
}

module acr 'modules/acr.bicep' = {
  scope: rg
  params: {
    name: '${abbrs.containerRegistry}${resourceToken}'
    location: location
    tags: {
      'azd-env-name': environmentName
    }
  }
}

module appService 'modules/appservice.bicep' = {
  scope: rg
  params: {
    appServiceName: '${abbrs.appService}${resourceToken}'
    appServicePlanName: '${abbrs.appServicePlan}${resourceToken}'
    location: location
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    tags: {
      'azd-env-name': environmentName
    }
  }
}

module ai 'modules/ai.bicep' = {
  scope: rg
  params: {
    aiServicesName: '${abbrs.aiServices}${resourceToken}'
    aiHubName: '${abbrs.aiHub}${resourceToken}'
    aiProjectName: '${abbrs.aiProject}${resourceToken}'
    location: location
    tags: {
      'azd-env-name': environmentName
    }
  }
}

output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_ACR_LOGIN_SERVER string = acr.outputs.loginServer
output AZURE_ACR_NAME string = acr.outputs.name
output APP_SERVICE_HOSTNAME string = appService.outputs.hostname
output AZURE_AI_SERVICES_ENDPOINT string = ai.outputs.aiServicesEndpoint
output AZURE_AI_PROJECT_ID string = ai.outputs.aiProjectId

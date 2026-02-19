@description('Name for the AI Services (Cognitive Services) account')
param aiServicesName string

@description('Name for the AI Hub workspace')
param aiHubName string

@description('Name for the AI Project workspace')
param aiProjectName string

@description('Location for the resources')
param location string

@description('Tags to apply to the resources')
param tags object = {}

// AI Services account (hosts model deployments)
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
  }
}

// GPT-4.1 model deployment
resource gpt41Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'gpt-41'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4.1'
      version: '2025-04-14'
    }
  }
}

// Phi-4 model deployment
resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'Phi-4'
  dependsOn: [gpt41Deployment]
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4'
      version: '7'
    }
  }
}

// Storage account required by AI Hub
var storageRaw = replace('st${aiHubName}', '-', '')
var storageName = take(storageRaw, 24)

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  #disable-next-line BCP334
  name: storageName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// Key Vault required by AI Hub
var kvName = take('kv-${aiHubName}', 24)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: length(kvName) >= 3 ? kvName : 'kv-${uniqueString(aiHubName)}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }
}

// AI Hub (parent workspace)
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: aiHubName
  location: location
  tags: tags
  kind: 'Hub'
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'AI Hub - ZavaStorefront'
    storageAccount: storageAccount.id
    keyVault: keyVault.id
  }
}

// Connection from AI Hub to AI Services
resource aiServicesConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-10-01' = {
  parent: aiHub
  name: '${aiServicesName}-connection'
  properties: {
    category: 'AIServices'
    authType: 'AAD'
    isSharedToAll: true
    target: aiServices.properties.endpoint
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiServices.id
    }
  }
}

// AI Project (child of Hub)
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: aiProjectName
  location: location
  tags: tags
  kind: 'Project'
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'ZavaStorefront AI Project'
    hubResourceId: aiHub.id
  }
}

@description('The endpoint of the AI Services account')
output aiServicesEndpoint string = aiServices.properties.endpoint

@description('The name of the AI Services account')
output aiServicesName string = aiServices.name

@description('The resource ID of the AI Hub')
output aiHubId string = aiHub.id

@description('The resource ID of the AI Project')
output aiProjectId string = aiProject.id

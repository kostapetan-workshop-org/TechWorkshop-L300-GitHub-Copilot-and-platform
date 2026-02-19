@description('Name of the Azure Container Registry')
param name string

@description('Location for the resource')
param location string

@description('Tags to apply to the resource')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

@description('The resource ID of the ACR')
output id string = acr.id

@description('The login server of the ACR')
output loginServer string = acr.properties.loginServer

@description('The name of the ACR')
output name string = acr.name

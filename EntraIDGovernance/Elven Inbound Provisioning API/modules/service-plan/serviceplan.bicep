// Azure App Service Plan and Hosting Plan - Bicep module
// Created by - Jan Vidar Elven

@description('The name of your app service plan')
param appServicePlanName string

@description('The environment (dev, test, prod, ...')
@maxLength(4)
param environment string = 'dev'

@description('A list of tags to apply to the resources')
param resourceTags object

@description('The Azure region where all resources in this module should be created')
param location string

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: resourceTags
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
  }
}

output appServicePlanId string = appServicePlan.id

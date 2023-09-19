// Hosting Plan - Bicep module
// Created by - Jan Vidar Elven

@description('The name of your hosting plan')
param hostingPlanName string

@description('The name of your sku for hosting plan')
param hostingPlanSkuName string

@description('The worker count capacity for hosting plan')
param hostingPlanSkuCapacity int

@description('The environment (dev, test, prod, ...')
@maxLength(4)
param environment string = 'dev'

@description('A list of tags to apply to the resources')
param resourceTags object

@description('The Azure region where all resources in this module should be created')
param location string

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: hostingPlanSkuName
    capacity: hostingPlanSkuCapacity
  }
  properties: {
  }
  tags: resourceTags
}

output hostingPlanId string = hostingPlan.id

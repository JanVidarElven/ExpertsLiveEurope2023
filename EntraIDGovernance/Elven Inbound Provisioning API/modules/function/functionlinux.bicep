// Azure Functions - Bicep module
// Created by - Jan Vidar Elven

@description('The name of your application')
param applicationName string

@description('The name of your application')
param functionAppName string

@description('The environment (dev, test, prod, ...')
@maxLength(4)
param environment string = 'dev'

@description('The Azure region where all resources in this module should be created')
param location string

@description('A list of tags to apply to the resources')
param resourceTags object

@description('The hosting app service plan id for the function app')
param hostingPlanId string

@description('Allowed origins array of strings for CORS setting')
param corsAllowedOrigins array

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  // kind: 'functionapp'
  tags: resourceTags
  properties: {
    httpsOnly: true
    serverFarmId: hostingPlanId
    siteConfig: {
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: corsAllowedOrigins
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }  
}

output application_url string = functionApp.properties.hostNames[0]
output webapp_name string = functionApp.properties.defaultHostName


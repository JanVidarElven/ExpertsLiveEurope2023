// Main Bicep deployment file for resources:
// Elven Inbound Provisioning API
// Created by: Jan Vidar Elven
// Last Updated: 05.07.2023

targetScope = 'subscription'

// If an environment is set up (dev, test, prod...), it is used in the application name
param environment string = 'prod'
param applicationName string = 'inboundprovisioning-api'
param location string = 'norwayeast'

var defaultTags = {
  Environment: environment
  Application: applicationName
  Dataclassification: 'Confidential'
  Costcenter: 'Operations'
  Criticality: 'Critical'
  Service: 'Elven Inbound Provisioning API'
  Deploymenttype: 'Bicep'
  Owner: 'Jan Vidar Elven'
  Business: 'Elven AS'
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-elven-${applicationName}'
  location: location
  tags: defaultTags
}

var storageName = 'elvensa${take(replace(applicationName, 'ing-api', ''),17)}'

module blobStorage 'modules/storage-blob/storage.bicep' = {
  name: 'storage'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    applicationName: applicationName
    environment: environment
    resourceTags: defaultTags
    storageName: storageName
  }
}

module fileShare 'modules/storage-fileshare/fileshare.bicep' = {
  name: 'fileshare'
  scope: resourceGroup(rg.name)
  params: {
    fileShareName: 'csvdata-prod'
    environment: environment
    storageName: storageName
    accessTier: 'TransactionOptimized'
  }
}

module hostingPlan 'modules/service-plan/hostingplan.bicep' = {
  name: 'servicePlan'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    hostingPlanName: 'hostingplan-function-sec-${applicationName}'
    hostingPlanSkuName: 'F1'
    hostingPlanSkuCapacity: 0
    environment: environment
    resourceTags: defaultTags
  }
}

module function 'modules/function/functionlinux.bicep' = {
  name: 'function'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    applicationName: applicationName
    functionAppName: 'elven-fa-sec-${applicationName}'
    environment: environment
    resourceTags: defaultTags
    hostingPlanId: hostingPlan.outputs.hostingPlanId
    corsAllowedOrigins: [
      '*'
    ]
  }
}

// The URL for the GitHub repository *CHANGE IF YOU HAVE FORKED THIS REPO*.

module sourcecontrol 'modules/function/sourcecontrol.bicep' = {
  name: 'sourcecontrol'
  scope: resourceGroup(rg.name)
  params: {
    parentWebAppName: 'elven-fa-sec-${applicationName}'
    repoURL: 'https://github.com/joelbyford/CSVtoJSONcore.git'
    branch: 'main'
  }
}

module fileConn 'modules/web-connection/fileconnection.bicep' = {
  name: 'webFileConnection'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    resourceTags: defaultTags
    webConnectionName: 'azurefile'
    storageAccountName: blobStorage.outputs.storageAccountName
    storageKey: blobStorage.outputs.storageKey
  }
}

module logicWorkflowCSV2SCIM 'modules/logic-workflow/logicapp.bicep' = {
  name: 'logicapp-eipapi-csv2scim'
  scope: resourceGroup(rg.name)
  params: {
    csvUri: 'https://${function.outputs.application_url}/csvtojson'
    csvDataPath: '/csvdata-prod/CSV_Batch_ExpertsLiveEU_Sep2023.csv'
    scimBulkEndpointAPIUri: 'your-provisioning-bulkUpload-api-endpoint'
    fileConnectionId: '/subscriptions/your-subscription-id/resourceGroups/rg-your-resource-group/providers/Microsoft.Web/connections/azurefile'
    fileConnectionName: 'azurefile'
    location: location
    resourceTags: defaultTags
    logicAppName: 'logicapp-eipapi-csv2scim'
  }  
}

module keyVault 'modules/keyvault/keyvault.bicep' = {
  name: 'kv'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    orgName: 'elven'
    applicationName: 'identity-api'
    environment: environment
    resourceTags: defaultTags
  }
}

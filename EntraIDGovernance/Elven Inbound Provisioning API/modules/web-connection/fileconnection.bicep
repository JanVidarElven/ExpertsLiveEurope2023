// Web Connections - Bicep module
// Created by - Jan Vidar Elven

@description('The name of your web connection')
param webConnectionName string

@description('The environment (dev, test, prod, ...')
@maxLength(4)
param environment string = 'dev'

@description('The Azure region where all resources in this module should be created')
param location string

@description('A list of tags to apply to the resources')
param resourceTags object

@description('The name of the storage account for which the file connection shall be made to')
param storageAccountName string

@description('The key for accessing the storage account connection')
@secure()
param storageKey string


/* "properties": {
  "api": {
    "id": "[concat('/subscriptions/',subscription().subscriptionId,'/providers/Microsoft.Web/locations/',parameters('logicAppLocation'),'/managedApis/azurefile')]"
  },
  "displayName": "[parameters('azurefile_displayName')]",
  "parameterValues": {
    "accountName": "[parameters('azurefile_accountName')]",
    "accessKey": "[parameters('azurefile_accessKey')]"
  }
} */

resource fileConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: webConnectionName
  location: location
  tags: resourceTags
  properties: {
    api: {
      // id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azurefile'
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azurefile')
    }
    displayName: 'CSVData'
    parameterValues: {
      accountName: storageAccountName
      accessKey: storageKey
    }
  }
}

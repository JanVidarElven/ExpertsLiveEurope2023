// Storage File Share - Bicep module
// Created by - Jan Vidar Elven

@description('The name of your File Share')
param fileShareName string

@description('The environment (dev, test, prod, ...')
@maxLength(4)
param environment string = 'dev'

@description('The name of the storage account to create. Max 24 characters.')
param storageName string

@description('The name of the container to create. Defaults to applicationName value.')
param accessTier string = 'TransactionOptimized'

resource csvFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: '${storageName}/default/${fileShareName}'
  properties: {
    accessTier: accessTier
  }
}

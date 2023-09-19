// Logic App - Bicep module
// Created by - Jan Vidar Elven

@description('The name of your Logic App')
param logicAppName string

@description('The Azure region where all resources in this module should be created')
param location string

@description('A list of tags to apply to the resources')
param resourceTags object

@description('The URI to the CSVToJSON converter service')
param csvUri string 

@description('The Data Path to the CSV file for converting to JSON')
param csvDataPath string

@description('The URI to the SCIM Bulk Endpoint API')
param scimBulkEndpointAPIUri string 

@description('The Resource ID of the File Web Connection')
param fileConnectionId string 

@description('The Connection Name of the File Web Connection')
param fileConnectionName string

@description('The ID of the type of File Connection')
param fileId string = subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azurefile')

var frequency = 'Hour'
var interval = '1'
var type = 'recurrence'
var workflowSchema = 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'

resource logicAppCSV2SCIMBulkUpload 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: resourceTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: {
      '$schema': workflowSchema
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        recurrence: {
          type: type
          recurrence: {
            frequency: frequency
            interval: interval
          }
        }
      }
      actions: {
        Convert_CSV_to_JSON: {
          runAfter: {
            Get_CSV_records: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            body: '@outputs(\'Get_CSV_records\')'
            headers: {
              'Content-Type': 'text/csv'
            }
            method: 'POST'
            uri: csvUri
          }
        }
        For_each: {
          foreach: '@variables(\'JSONInputArray\')'
          actions: {
            Condition: {
              actions: {
                Append_last_SCIMUser_record_in_the_chunk: {
                  runAfter: {}
                  type: 'AppendToStringVariable'
                  inputs: {
                    name: 'SCIMBulkPayload'
                    value: '@outputs(\'Construct_SCIMUser\')'
                  }
                }
                Finalize_SCIMBulkPayload: {
                  runAfter: {
                    Append_last_SCIMUser_record_in_the_chunk: [
                      'Succeeded'
                    ]
                  }
                  type: 'AppendToStringVariable'
                  inputs: {
                    name: 'SCIMBulkPayload'
                    value: '  ],\n  "failOnErrors": null\n}'
                  }
                }
                Prepare_next_chunk_of_SCIMBulkPayload: {
                  runAfter: {
                    Reset_Iteration_Count: [
                      'Succeeded'
                      'Skipped'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'SCIMBulkPayload'
                    value: '{\n  "schemas": [\n    "urn:ietf:params:scim:api:messages:2.0:BulkRequest"\n  ],\n  "Operations": ['
                  }
                }
                Reset_Iteration_Count: {
                  runAfter: {
                    Send_SCIMBulkPayload_to_API_endpoint: [
                      'Succeeded'
                      'Skipped'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'IterationCount'
                    value: 0
                  }
                }
                Send_SCIMBulkPayload_to_API_endpoint: {
                  runAfter: {
                    View_SCIMBulkPayload: [
                      'Succeeded'
                    ]
                  }
                  type: 'Http'
                  inputs: {
                    authentication: {
                      audience: 'https://graph.microsoft.com'
                      type: 'ManagedServiceIdentity'
                    }
                    body: '@variables(\'SCIMBulkPayload\')'
                    headers: {
                      'Content-Type': 'application/scim+json'
                    }
                    method: 'POST'
                    uri: scimBulkEndpointAPIUri
                  }
                  operationOptions: 'DisableAsyncPattern'
                }
                View_SCIMBulkPayload: {
                  runAfter: {
                    Finalize_SCIMBulkPayload: [
                      'Succeeded'
                    ]
                  }
                  type: 'Compose'
                  inputs: '@variables(\'SCIMBulkPayload\')'
                }
              }
              runAfter: {
                Construct_SCIMUser: [
                  'Succeeded'
                ]
              }
              else: {
                actions: {
                  Append_SCIMUser_record: {
                    runAfter: {}
                    type: 'AppendToStringVariable'
                    inputs: {
                      name: 'SCIMBulkPayload'
                      value: '@concat(outputs(\'Construct_SCIMUser\'),\',\')'
                    }
                  }
                }
              }
              expression: {
                or: [
                  {
                    equals: [
                      '@variables(\'NumberOfRecordsToProcess\')'
                      0
                    ]
                  }
                  {
                    equals: [
                      '@variables(\'IterationCount\')'
                      50
                    ]
                  }
                ]
              }
              type: 'If'
            }
            Construct_SCIMUser: {
              runAfter: {
                Decrement_NumberOfRecords_: [
                  'Succeeded'
                ]
              }
              type: 'Compose'
              inputs: {
                bulkId: '@{guid()}'
                data: {
                  active: '@if(equals(items(\'For_each\')?[\'EmployeeStatus\'],\'Active\'),true,false)'
                  addresses: [
                    {
                      country: '@{items(\'For_each\')?[\'Country\']}'
                      formatted: '@{items(\'For_each\')?[\'Office\']}'
                      locality: '@{items(\'For_each\')?[\'City\']}'
                      postalCode: '@{items(\'For_each\')?[\'PostalCode\']}'
                      primary: true
                      region: '@{items(\'For_each\')?[\'Region\']}'
                      streetAddress: '@{items(\'For_each\')?[\'OfficeStreetAddress\']}'
                      type: 'work'
                    }
                  ]
                  displayName: '@{items(\'For_each\')?[\'DisplayName\']}'
                  emails: [
                    {
                      primary: true
                      type: 'work'
                      value: '@{items(\'For_each\')?[\'UPN\']}'
                    }
                  ]
                  externalId: '@{items(\'For_each\')?[\'EmployeeUserName\']}'
                  id: '@{items(\'For_each\')?[\'EmployeeUserName\']}'
                  locale: 'nb-NO'
                  name: {
                    familyName: '@{items(\'For_each\')?[\'LastName\']}'
                    givenName: '@{items(\'For_each\')?[\'FirstName\']}'
                  }
                  nickName: '@{items(\'For_each\')?[\'Alias\']}'
                  phoneNumbers: [
                    {
                      type: 'mobile'
                      value: '@{items(\'For_each\')?[\'MobilePhone\']}'
                    }
                  ]
                  preferredLanguage: 'nb-NO'
                  schemas: [
                    'urn:ietf:params:scim:schemas:core:2.0:User'
                    'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User'
                    'urn:ietf:params:scim:schemas:extension:csv:1.0:User'
                    'urn:ietf:params:scim:schemas:extension:elven:1.0:User'
                  ]
                  timezone: 'Norway/Oslo'
                  title: '@{items(\'For_each\')?[\'Title\']}'
                  'urn:ietf:params:scim:schemas:extension:csv:1.0:User': {
                    HireDate: '@{If(empty(items(\'For_Each\')?[\'EmployeeStartDateTime\']),false,convertToUtc(parseDateTime(items(\'For_Each\')?[\'EmployeeStartDateTime\'],\'nb-no\'), \'W. Europe Standard Time\'))}'
                  }
                  'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User': {
                    costCenter: '@{items(\'For_each\')?[\'CostCenter\']}'
                    department: '@{items(\'For_each\')?[\'Department\']}'
                    division: '@{items(\'For_each\')?[\'Division\']}'
                    employeeNumber: '@{items(\'For_each\')?[\'EmployeeID\']}'
                    manager: {
                      '$ref': '../Users/@{items(\'For_each\')?[\'Manager\']}'
                      displayName: '@{items(\'For_each\')?[\'Manager\']}'
                      value: '@{items(\'For_each\')?[\'Manager\']}'
                    }
                    organization: '@{items(\'For_each\')?[\'Company\']}'
                  }
                  'urn:ietf:params:scim:schemas:extension:elven:1.0:User': {
                    countryCode: '@{items(\'For_each\')?[\'Country\']}'
                  }
                  userName: '@{items(\'For_each\')?[\'Alias\']}'
                  userType: '@{items(\'For_each\')?[\'EmployeeType\']}'
                }
                method: 'POST'
                path: '/Users'
              }
            }
            Decrement_NumberOfRecords_: {
              runAfter: {
                Increment_IterationCount: [
                  'Succeeded'
                ]
              }
              type: 'DecrementVariable'
              inputs: {
                name: 'NumberOfRecordsToProcess'
                value: 1
              }
            }
            Increment_IterationCount: {
              runAfter: {}
              type: 'IncrementVariable'
              inputs: {
                name: 'IterationCount'
                value: 1
              }
            }
          }
          runAfter: {
            Initialize_InvocationDateTime: [
              'Succeeded'
            ]
          }
          type: 'Foreach'
          runtimeConfiguration: {
            concurrency: {
              repetitions: 1
            }
          }
        }
        Get_CSV_records: {
          runAfter: {
            Get_file_content_using_path: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: '@body(\'Get_file_content_using_path\')'
        }
        Get_file_content_using_path: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azurefile\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/datasets/default/GetFileContentByPath'
            queries: {
              inferContentType: true
              path: csvDataPath
              queryParametersSingleEncoded: true
            }
          }
        }
        Initialize_InvocationDateTime: {
          runAfter: {
            Initialize_SCIMBulkPayload: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'InvocationDateTime'
                type: 'string'
                value: '@{utcNow()}'
              }
            ]
          }
        }
        Initialize_IterationCount: {
          runAfter: {
            Initialize_NumberOfRecordsToProcess: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'IterationCount'
                type: 'integer'
                value: 0
              }
            ]
          }
        }
        Initialize_JSONInputArray: {
          runAfter: {
            Parse_JSON: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'JSONInputArray'
                type: 'array'
                value: '@body(\'Parse_JSON\')?[\'rows\']'
              }
            ]
          }
        }
        Initialize_NumberOfRecordsToProcess: {
          runAfter: {
            Initialize_JSONInputArray: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'NumberOfRecordsToProcess'
                type: 'integer'
                value: '@length(body(\'Parse_JSON\')?[\'rows\'])'
              }
            ]
          }
        }
        Initialize_SCIMBulkPayload: {
          runAfter: {
            Initialize_IterationCount: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'SCIMBulkPayload'
                type: 'string'
                value: '{\n  "schemas": [\n    "urn:ietf:params:scim:api:messages:2.0:BulkRequest"\n  ],\n  "Operations": [\n'
              }
            ]
          }
        }
        Parse_JSON: {
          runAfter: {
            Convert_CSV_to_JSON: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'Convert_CSV_to_JSON\')'
            schema: {
              properties: {
                rows: {
                  items: {
                    properties: {
                      Alias: {
                        type: 'string'
                      }
                      City: {
                        type: 'string'
                      }
                      Company: {
                        type: 'string'
                      }
                      CostCenter: {
                        type: 'string'
                      }
                      Country: {
                        type: 'string'
                      }
                      Department: {
                        type: 'string'
                      }
                      DisplayName: {
                        type: 'string'
                      }
                      Division: {
                        type: 'string'
                      }
                      EmployeeID: {
                        type: 'string'
                      }
                      EmployeeLeaveDateTime: {
                        type: 'string'
                      }
                      EmployeeStartDateTime: {
                        type: 'string'
                      }
                      EmployeeStatus: {
                        type: 'string'
                      }
                      EmployeeTerminationDateTime: {
                        type: 'string'
                      }
                      EmployeeType: {
                        type: 'string'
                      }
                      EmployeeUserName: {
                        type: 'string'
                      }
                      FirstName: {
                        type: 'string'
                      }
                      LastName: {
                        type: 'string'
                      }
                      Manager: {
                        type: 'string'
                      }
                      MobilePhone: {
                        type: 'string'
                      }
                      Office: {
                        type: 'string'
                      }
                      OfficeStreetAddress: {
                        type: 'string'
                      }
                      PostalCode: {
                        type: 'string'
                      }
                      Region: {
                        type: 'string'
                      }
                      Title: {
                        type: 'string'
                      }
                      UPN: {
                        type: 'string'
                      }
                    }
                    required: [
                      'EmployeeID'
                      'EmployeeUserName'
                      'EmployeeStatus'
                      'FirstName'
                      'LastName'
                      'DisplayName'
                      'Alias'
                      'UPN'
                      'Country'
                      'Company'
                      'MobilePhone'
                      'EmployeeStartDateTime'
                      'EmployeeLeaveDateTime'
                      'EmployeeTerminationDateTime'
                      'EmployeeType'
                      'Manager'
                      'Office'
                      'OfficeStreetAddress'
                      'City'
                      'Region'
                      'PostalCode'
                      'Title'
                      'Department'
                      'CostCenter'
                      'Division'
                    ]
                    type: 'object'
                  }
                  type: 'array'
                }
              }
              type: 'object'
            }
          }
        }        
      }
    }
    parameters: {
      '$connections': {
        value: {
          azurefile: {
            connectionId: fileConnectionId
            connectionName: fileConnectionName
            id: fileId
          }
        }
      }
    }    
  }
}


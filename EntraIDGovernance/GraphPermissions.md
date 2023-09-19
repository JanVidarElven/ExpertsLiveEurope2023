# How to add Microsoft Graph Application Permissions to Service Principals

## 1. Find your Service Principal Id

https://graph.microsoft.com/v1.0/servicePrincipals?$search="displayName:msi"&$count=true

## 2. Find your Graph Resource Id

https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '00000003-0000-0000-c000-000000000000'

## 3. Find the App Role you want to assign permission to

https://graph.microsoft.com/v1.0/servicePrincipals/<your-graph-resource-id>/appRoles/

Some examples:

```json
            "displayName": "Upload user data to the identity synchronization service",
            "id": "db31e92a-b9ea-4d87-bf6a-75a37a9ca35a",
            "isEnabled": true,
            "origin": "Application",
            "value": "SynchronizationData-User.Upload"

            "displayName": "Read and write all users' authentication methods ",
            "id": "50483e42-d915-4231-9639-7fdb7fd190e5",
            "isEnabled": true,
            "origin": "Application",
            "value": "UserAuthenticationMethod.ReadWrite.All"

```

## 4.  Assign the permission

POST https://graph.microsoft.com/v1.0/servicePrincipals/<your-graph-resource-id>//appRoleAssignedTo

Content-Type: application/json

Body:

```json
{
  "principalId": "..",
  "resourceId": "..",
  "appRoleId": ".."
}
```

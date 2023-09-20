# Install Current User
Install-Module -Name Microsoft.Graph -Scope CurrentUser

# Install for All Users (Admin privilege)
Install-Module -Name Microsoft.Graph -Scope AllUsers

# Install Beta
Install-Module -Name Microsoft.Graph.Beta

Get-Module -Name Microsoft.Graph -ListAvailable -All

Get-InstalledModule -Name Microsoft.Graph.*

# Interactive authentication:
Connect-MgGraph

# Interactive authentication with specified tenant:
Connect-MgGraph -TenantId yourtenant.onmicrosoft.com

# Device authentication:
Connect-MgGraph -UseDeviceAuthentication

# Access token: 
Connect-MgGraph -AccessToken $AccessToken

# Application:
Connect-MgGraph -ClientId "YOUR_APP_ID" -TenantId "YOUR_TENANT_ID" -CertificateThumbprint "YOUR_CERT_THUMBPRINT"

# Managed Identity:
Connect-MgGraph -Identity

# Connect with Scopes
Connect-MgGraph -Scopes User.Read.All, Group.ReadWrite.All 

# Find necessary permissions
Find-MgGraphCommand -command Get-MgUser | 
 Select -First 1 -ExpandProperty Permissions

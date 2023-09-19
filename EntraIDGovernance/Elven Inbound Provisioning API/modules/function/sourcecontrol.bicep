
@description('The name of the parent web app name.')
param parentWebAppName string

@description('The URL for the GitHub repository.')
param repoURL string

@description('The branch of the GitHub repository to use.')
param branch string

resource webapp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: parentWebAppName
}

resource siteName_web 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: webapp
  name: 'web'
  properties: {
    repoUrl: repoURL
    branch: branch
    isManualIntegration: true
  }
}

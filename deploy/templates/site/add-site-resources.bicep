

/*----------------------------------Params-------------------------------*/
param location string
param siteName string
param appServicePlanName string
param userAssignedIdentityName string

/*----------------------------------Existing App Service Plan-----------*/
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' existing = {
  name: appServicePlanName
}
param deploymentStorageAccountName string
param logsStorageAccountName string
param appInsightsName string
param keyVaultName string = ''

@description('Base URL path for the app (e.g., "docs" for /docs)')
param appBasePath string = ''

@description('Enable authentication on the site')
param enableAuthentication bool = true

@description('Entra ID (Azure AD) application client ID for EasyAuth')
param entraIdClientId string = ''

@description('Entra ID (Azure AD) tenant ID')
param entraIdTenantId string = subscription().tenantId

/*----------------------------------Existing Core Resources-------------*/
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: userAssignedIdentityName
}

resource deploymentStorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: deploymentStorageAccountName
}

resource logsStorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: logsStorageAccountName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

/*----------------------------------Web App-----------------------------*/
module webApp './webapp.bicep' = {
  name: 'webapp-${siteName}'
  params: {
    location: location
    serverFarmResourceId: appServicePlan.id
    siteName: siteName
    keyVaultName: keyVaultName
    appBasePath: appBasePath
    enableAuthentication: enableAuthentication
    userAssignedIdentityResourceId: userAssignedIdentity.id
    deploymentStorageAccountResourceId: deploymentStorageAccount.id
    applicationInsightsResourceId: appInsights.id
    logsModuleStorageAccountResourceId: logsStorageAccount.id
    entraIdClientId: entraIdClientId
    entraIdTenantId: entraIdTenantId
  }
}

/*----------------------------------Outputs-----------------------------*/
output siteDefaultHostname string = webApp.outputs.webAppDomain
output siteResourceName string = webApp.outputs.webAppResourceName

targetScope = 'subscription'

/*----------------------------------Params-------------------------------*/
@description('The environment unique name')
param environmentName string

@description('The resources prefix')
param resourcePrefix string

param location string = deployment().location

@description('Resource group name where core infrastructure is deployed')
param rgName string

@description('Unique name for the new site (e.g. "blog", "docs")')
param appName string

@description('Base URL path for the app (e.g., "docs" for /docs)')
param appBasePath string = ''

@description('Enable authentication on the site')
param enableAuthentication bool = true

@description('Entra ID (Azure AD) application client ID for EasyAuth')
param entraIdClientId string = ''

@description('Entra ID (Azure AD) tenant ID')
param entraIdTenantId string = subscription().tenantId

/*----------------------------------Variables---------------------------*/

var resourceToken = take(toLower(uniqueString(subscription().id, environmentName, location)), 5)

var resourceName = !empty(resourcePrefix) ? resourcePrefix : toLower(split(split(environmentName, '-')[0], '_')[0])

// Compute names of existing core infrastructure resources
var userAssignedIdentityName = 'id-${resourceName}-${resourceToken}'
var deploymentStorageAccountName = 'st${resourceName}${resourceToken}'
var logsStorageAccountName = 'st${resourceName}logs${resourceToken}'
var appInsightsName = 'appi-${resourceName}-${resourceToken}'
var keyVaultName = 'kv-${resourceName}-${resourceToken}'

// Shared App Service Plan name (created by core infra)
var appServicePlanName = 'plan-${resourceName}-${resourceToken}'

// New site resource name
var siteName = 'app-${resourceName}-${!empty(appBasePath) ? appBasePath : appName}-${resourceToken}'

/*----------------------------------Add Site Resources------------------*/
module addSiteResources './add-site-resources.bicep' = {
  scope: resourceGroup(rgName)
  name: 'dep-add-site-${siteName}-${resourceToken}'
  params: {
    location: location
    siteName: siteName
    appBasePath: appBasePath
    appServicePlanName: appServicePlanName
    userAssignedIdentityName: userAssignedIdentityName
    deploymentStorageAccountName: deploymentStorageAccountName
    logsStorageAccountName: logsStorageAccountName
    appInsightsName: appInsightsName
    keyVaultName: keyVaultName
    enableAuthentication: enableAuthentication
    entraIdClientId: entraIdClientId
    entraIdTenantId: entraIdTenantId
  }
}

/*----------------------------------Outputs-----------------------------*/
@description('Default hostname of the newly created web app (e.g. app-docusaurops-blog-ah4tb.azurewebsites.net)')
output siteDefaultHostname string = addSiteResources.outputs.siteDefaultHostname

@description('Resource name of the newly created web app')
output siteResourceName string = addSiteResources.outputs.siteResourceName

@description('Name of the Application Gateway (for route updates)')
output appGatewayName string = 'agw-${resourceName}-${resourceToken}'

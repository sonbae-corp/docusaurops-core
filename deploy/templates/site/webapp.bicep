@description('Location of resources')
param location string

@description('The app service name')
param siteName string

@description('Resource ID of the shared App Service Plan')
param serverFarmResourceId string

@description('User assigned identity resource ID')
param userAssignedIdentityResourceId string

@description('Storage account resource ID')
param deploymentStorageAccountResourceId string

@description('Storage account resource ID for logs')
param logsModuleStorageAccountResourceId string

@description('Application Insights resource ID')
param applicationInsightsResourceId string

@description('Base URL path for the app (e.g., "docs" for /docs)')
param appBasePath string = ''

@description('Enable authentication on the site')
param enableAuthentication bool = true

@description('Key Vault name for secret references')
param keyVaultName string = ''

@description('Entra ID (Azure AD) application client ID for EasyAuth')
param entraIdClientId string = ''

@description('Entra ID (Azure AD) tenant ID. Defaults to current tenant.')
param entraIdTenantId string = subscription().tenantId

var webAppHostUrl = 'https://${siteName}.azurewebsites.net'
var entraIdEnabled = enableAuthentication && !empty(entraIdClientId)

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: last(split(userAssignedIdentityResourceId, '/'))
}

resource deploymentStorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: last(split(deploymentStorageAccountResourceId, '/'))
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: last(split(applicationInsightsResourceId, '/'))
}

module webApp 'br/public:avm/res/web/site:0.19.3' = {
  name: 'webapp'
  params: {
    kind: 'app,linux'
    name: siteName
    location: location

    publicNetworkAccess: 'Enabled'

    serverFarmResourceId: serverFarmResourceId
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        userAssignedIdentityResourceId
      ]
    }

    keyVaultAccessIdentityResourceId: userAssignedIdentityResourceId

    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'NODE|24-lts'
      alwaysOn: false
      cors: {
        allowedOrigins: ['*']
        supportCredentials: false
      }            
    }

    configs: [
      {
        name: 'appsettings'
        properties:{
          AzureWebJobsStorage__credential: 'managedidentity'
          AzureWebJobsStorage__blobServiceUri: 'https://${deploymentStorageAccount.name}.blob.${environment().suffixes.storage}'
          AzureWebJobsStorage__queueServiceUri: 'https://${deploymentStorageAccount.name}.queue.${environment().suffixes.storage}'
          AzureWebJobsStorage__tableServiceUri: 'https://${deploymentStorageAccount.name}.table.${environment().suffixes.storage}'
          AzureWebJobsStorage__accountName: deploymentStorageAccount.name
          AzureWebJobsStorage__clientId: userAssignedIdentity.properties.clientId
          APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
          APPLICATIONINSIGHTS_AUTHENTICATION_STRING: 'ClientId=${userAssignedIdentity.properties.clientId};Authorization=AAD'
          MICROSOFT_PROVIDER_AUTHENTICATION_SECRET: entraIdEnabled && !empty(keyVaultName) ? '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}${environment().suffixes.keyvaultDns}/secrets/MICROSOFTPROVIDERAUTHENTICATIONSECRET)' : ''
        }
      }      
  ]
    
    diagnosticSettings: [
      {
        name: siteName
        storageAccountResourceId: logsModuleStorageAccountResourceId
      }
    ]
  }
}

resource authSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  name: '${siteName}/authsettingsV2'
  dependsOn: [webApp]
  properties: {
    httpSettings: {
      requireHttps: enableAuthentication
      routes: {
        apiPrefix: enableAuthentication ? (!empty(appBasePath) ? '/${appBasePath}/.auth' : '/.auth') : ''
      }
      forwardProxy: enableAuthentication ? {
        convention: 'Custom'
        customHostHeaderName: 'X-Original-Host'
      } : null
    }
    login: enableAuthentication ? {
      allowedExternalRedirectUrls: [
        !empty(appBasePath) ? '${webAppHostUrl}/${appBasePath}/.auth/login/aad/callback' : '${webAppHostUrl}/.auth/login/aad/callback'
      ]
      tokenStore: {
        enabled: true
      }
    } : null
    platform: {
      enabled: entraIdEnabled
    }
    globalValidation: {
      requireAuthentication: entraIdEnabled
      unauthenticatedClientAction: entraIdEnabled ? 'RedirectToLoginPage' : 'AllowAnonymous'
    }
    identityProviders: entraIdEnabled ? {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: entraIdClientId
          clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
          openIdIssuer: 'https://sts.windows.net/${entraIdTenantId}/v2.0'
        }
        login: {
          loginParameters: [
            'scope=openid profile email offline_access https://graph.microsoft.com/.default'
          ]
        }
        validation: {
          allowedAudiences: [
            'api://${entraIdClientId}'
          ]
        }
      }
    } : {}
  }
}


output webAppDomain string = webApp.outputs.defaultHostname
output webAppResourceName string = webApp.outputs.name
output webAppResourceId string = webApp.outputs.resourceId

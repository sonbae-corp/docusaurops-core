targetScope = 'subscription'

import {
  RBACPrincipalType
} from '../types.bicep'

/*----------------------------------Params-------------------------------*/
@description('The environment unique name')
param environmentName string

@description('The resources prefix')
param resourcePrefix string

@metadata({
  azd: {
    type: 'location'
  }
})
param location string = deployment().location

@description('Resource group name where resources should be created')
param rgName string

@description('Subnet URI for the Application Gateway')
param subnetUriForAppGateway string = ''

@description('List of principals to configure for resource RBAC permissions')
param rbacPrincipalsList RBACPrincipalType[] = [
  {
    principalId: deployer().objectId
    principalType: 'ServicePrincipal'
  }
]

@description('Name for the root site (e.g. "root")')
param rootSiteName string = 'root'

@description('Password for the Application Gateway SSL PFX certificate')
@secure()
param sslCertificatePassword string = ''

@description('Base64-encoded PFX certificate data for the Application Gateway SSL certificate')
@secure()
param sslCertificateData string = ''

@description('Additional backend address pools to preserve on the Application Gateway')
param additionalBackendAddressPools array = []

@description('Additional path rules to preserve on the Application Gateway')
param additionalPathRules array = []

@description('Additional backend HTTP settings to preserve on the Application Gateway')
param additionalBackendHttpSettings array = []

@description('Additional health probes to preserve on the Application Gateway')
param additionalProbes array = []

/*----------------------------------Variables---------------------------*/

var tags = {
  'azd-env-name': environmentName
}

var resourceToken = take(toLower(uniqueString(subscription().id, environmentName, location)), 5)

var resourceName = !empty(resourcePrefix) ? resourcePrefix : toLower(split(split(environmentName, '-')[0], '_')[0])

var appServicePlanName = 'plan-${resourceName}-${resourceToken}'

/*----------------------------------Resource group----------------------*/
module rg 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'dep-rg-${resourceToken}'
  params: {
    name: rgName
    location: location
  }
}
  
/*----------------------------------User Assigned Identity--------------*/
module appUserAssignedIdentityModule 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  scope: resourceGroup(rgName)
  name: 'dep-userAssignedIdentity-${resourceToken}'
  params: {
    name: 'id-${resourceName}-${resourceToken}'
  }
  dependsOn: [rg]
}

/*----------------------------------Logs--------------------------------*/
module logsModule './logs.bicep' = {
  name: 'dep-logsModule-${resourceToken}'
  scope: resourceGroup(rgName)
  params: {
    storageAccountName: 'st${resourceName}logs${resourceToken}'
    location: location
    userAssignedIdentityResourceName: appUserAssignedIdentityModule.outputs.name
  }
}

/*----------------------------------Logs Diagnostic Settings------------*/
module logsDiagnostics './logs-diagnostics.bicep' = {
  scope: resourceGroup(rgName)
  name: 'dep-logsDiagnostics-${resourceToken}'
  params: {
    storageAccountName: logsModule.outputs.name
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
  }
}

/*----------------------------------Storage Account---------------------*/
module saModule './sa.bicep' = {
  scope: resourceGroup(rgName)
  name: 'dep-sa-${resourceToken}'
  params: {
    rbacPrincipalsList: rbacPrincipalsList
    location: location
    storageAccountName: 'st${resourceName}${resourceToken}'
    storageAccountResourceId: logsModule.outputs.resourceId
    userAssignedIdentityResourceName: appUserAssignedIdentityModule.outputs.name
  }
}

/*----------------------------------Log Analytics workspace-------------*/
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.11.2' = {
  scope: resourceGroup(rgName)
  name: 'dep-logAnalyticsWorkspace-${resourceToken}'
  params: {
    name: 'log-${resourceName}-${resourceToken}'

    location: location
    linkedStorageAccounts: [
      {
        name: 'Query'
        storageAccountIds: [
          saModule.outputs.resourceId
        ]
      }
    ]

    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'

    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        appUserAssignedIdentityModule.outputs.resourceId
      ]
    }

    roleAssignments: [
      {
        principalId: appUserAssignedIdentityModule.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Monitoring Contributor'
      }
    ]
  }
}

/*----------------------------------App Insights------------------------*/
module appInsights 'br/public:avm/res/insights/component:0.6.0' = {
  scope: resourceGroup(rgName)
  name: 'dep-appInsights-${resourceToken}'
  params: {
    name: 'appi-${resourceName}-${resourceToken}'

    location: location

    kind: 'web'

    linkedStorageAccountResourceId: saModule.outputs.resourceId
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId

    publicNetworkAccessForIngestion: 'Enabled' 
    publicNetworkAccessForQuery: 'Enabled'
    forceCustomerStorageForProfiler: false
    retentionInDays: 180

    disableIpMasking: false
    disableLocalAuth: true

    roleAssignments: [
      {
        principalId: appUserAssignedIdentityModule.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Monitoring Contributor'
      }
      {
        principalId: appUserAssignedIdentityModule.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Monitoring Metrics Publisher'
      }
      {
        principalId: appUserAssignedIdentityModule.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Application Insights Component Contributor'
      }
    ]    
  }
}

/*----------------------------------Shared App Service Plan-------------*/
module appServicePlanModule 'br/public:avm/res/web/serverfarm:0.1.1' = {
  scope: resourceGroup(rgName)
  name: 'dep-appServicePlan-${resourceToken}'
  params: {
    name: appServicePlanName
    sku: {
      name: 'B1'
      tier: 'Basic'
    }
    reserved: true
    location: location
    perSiteScaling: false
  }
  dependsOn: [rg]
}

/*----------------------------------Key Vault---------------------------*/
module kvModule './kv.bicep' = {
  scope: resourceGroup(rgName)
  name: 'dep-kv-${resourceToken}'
  params: {
    kvName: 'kv-${resourceName}-${resourceToken}'
    location: location
    rbacPrincipalsList: rbacPrincipalsList
    userAssignedIdentityResourceName: appUserAssignedIdentityModule.outputs.name
    storageAccountResourceId: logsModule.outputs.resourceId
    tags: tags
  }
  dependsOn: [rg]
}

/*----------------------------------Public IP (non-production only)---------------*/
module publicIpModule 'br/public:avm/res/network/public-ip-address:0.12.0' = {
  scope: resourceGroup(rgName)
  params: {
    name: 'pip-${resourceName}-${resourceToken}'
    location: location
    tags: tags
    skuName: 'Standard'
    availabilityZones: [1, 2, 3]
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'docusaurops-${environmentName}'
    }
  }
  dependsOn: [rg]
}

/*----------------------------------VNET + Subnet for application gateway (non-production only)---------------*/
module appGatewayVnetModule 'br/public:avm/res/network/virtual-network:0.7.2' = {
  scope: resourceGroup(rgName)
  name: 'dep-appGatewayVnet-${resourceToken}'
  params: {
    name: 'vnet-${resourceName}-${resourceToken}'
    location: location
    addressPrefixes: [
      '10.203.0.0/16'
    ]
    subnets: [
      {
        name: 'snet-${resourceName}-${resourceToken}'
        addressPrefix: '10.203.0.0/24'
      }
    ]
    tags: tags
  }
  dependsOn: [rg]
}

/*----------------------------------Application Gateway----------------------------*/
module appGatewayModule './gateway.bicep' = {
  scope: resourceGroup(rgName)
  name: 'dep-appGateway-${resourceToken}'
  dependsOn: [appGatewayVnetModule]
  params: {
    appGatewayName: 'agw-${resourceName}-${resourceToken}'
    location: location
    skuName: 'Standard_v2'
    skuCapacity: 1
    enableAutoscale: false
    autoscaleMinCapacity: 2
    autoscaleMaxCapacity: 10
    rootBackendName: rootSiteName
    rootProbePath: '/'
    subnetResourceId: !empty(subnetUriForAppGateway)
      ? subnetUriForAppGateway
      : resourceId(
          subscription().subscriptionId,
          rgName,
          'Microsoft.Network/virtualNetworks/subnets',
          'vnet-${resourceName}-${resourceToken}',
          'snet-${resourceName}-${resourceToken}'
        )
    publicIpResourceId: publicIpModule.?outputs.resourceId ?? ''
    sslCertificateName: 'docusaurops'
    sslCertificateData: sslCertificateData
    sslCertificatePassword: sslCertificatePassword
    enableHttp2: true
    enableFIPS: false
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    additionalBackendAddressPools: additionalBackendAddressPools
    additionalPathRules: additionalPathRules
    additionalBackendHttpSettings: additionalBackendHttpSettings
    additionalProbes: additionalProbes
  }
}

output azureAppInsightsConnectionString string = appInsights.outputs.connectionString
output azureKeyVaultName string = kvModule.outputs.kvName
output userManagedIdentityClientId string = appUserAssignedIdentityModule.outputs.clientId

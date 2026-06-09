import {
  RBACPrincipalType
} from '../types.bicep'


@description('A list of Azure Active Directory principals (users, groups, or service principals) and their types to be assigned specific roles for resource access')
param rbacPrincipalsList RBACPrincipalType[]

@description('User assigned identity to be assigned to this resource')
param userAssignedIdentityResourceName string

@description('Name of the search service resource')
param storageAccountName string

@description('Region location')
param location string


@description('Storage Account resource id for diagnostic settings')
param storageAccountResourceId string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = {
  name: userAssignedIdentityResourceName
}

var rbacStorageBlobDataContributor = [
  for p in rbacPrincipalsList: {
    principalId: p.principalId
    principalType: p.principalType
    roleDefinitionIdOrName: 'Storage Blob Data Contributor'
  }
]

var rbacStorageAccount = concat(rbacStorageBlobDataContributor, [
  {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionIdOrName: 'Storage Account Contributor'
  }
  {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionIdOrName: 'Storage Blob Data Owner'
  }
])

module sa 'br/public:avm/res/storage/storage-account:0.31.0' = {
  params: {
    name: storageAccountName
    location: location

    kind: 'StorageV2'
    skuName: 'Standard_LRS'

    allowSharedKeyAccess: false
    publicNetworkAccess: 'Enabled' 
    allowBlobPublicAccess: true

    fileServices: {
      shareDeleteRetentionPolicy: {
        allowPermanentDelete: true
        enabled: false
      }

      diagnosticSettings: [
        {
          metricCategories: [
            {
              category: 'AllMetrics'
            }
          ]
          name: '${storageAccountName}-file'
          storageAccountResourceId: storageAccountResourceId
        }
      ]
    }

    blobServices: {
      containerDeleteRetentionPolicyEnabled: false
      deleteRetentionPolicyEnabled: false
      containerDeleteRetentionPolicyAllowPermanentDelete: true
      deleteRetentionPolicyAllowPermanentDelete: true
      isVersioningEnabled: false
      restorePolicyEnabled: false

      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: [
            'DELETE'
            'GET'
            'HEAD'
            'OPTIONS'
            'PATCH'
            'POST'
            'PUT'
          ]
          maxAgeInSeconds: 20
          exposedHeaders: ['*']
          allowedHeaders: ['*']
        }
      ]

      diagnosticSettings: [
        {
          metricCategories: [
            {
              category: 'AllMetrics'
            }
          ]
          name: '${storageAccountName}-blob'
          storageAccountResourceId: storageAccountResourceId
        }
      ]
    }
    
    queueServices: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: [
            'DELETE'
            'GET'
            'HEAD'
            'OPTIONS'
            'POST'
          ]
          maxAgeInSeconds: 20
          exposedHeaders: ['*']
          allowedHeaders: ['*']
        }
      ]

      diagnosticSettings: [
        {
          metricCategories: [
            {
              category: 'AllMetrics'
            }
          ]
          name: '${storageAccountName}-queue'
          storageAccountResourceId: storageAccountResourceId
        }
      ]
    }

    tableServices: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: [
            'DELETE'
            'GET'
            'HEAD'
            'OPTIONS'
            'POST'
          ]
          maxAgeInSeconds: 20
          exposedHeaders: ['*']
          allowedHeaders: ['*']
        }
      ]

      diagnosticSettings: [
        {
          metricCategories: [
            {
              category: 'AllMetrics'
            }
          ]
          name: '${storageAccountName}-table'
          storageAccountResourceId: storageAccountResourceId
        }
      ]
    }

    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'

    roleAssignments: rbacStorageAccount

    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds:[
        userAssignedIdentity.id
      ]
    }

    allowCrossTenantReplication: false

    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: storageAccountName
        storageAccountResourceId: storageAccountResourceId
      }
    ]
    requireInfrastructureEncryption: true
  }
}

output resourceId string = sa.outputs.resourceId
output name string = sa.outputs.name

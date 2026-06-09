param location string
param storageAccountName string

@description('User assigned identity to be assigned to this resource')
param userAssignedIdentityResourceName string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = {
  name: userAssignedIdentityResourceName
}

module saLogs 'br/public:avm/res/storage/storage-account:0.31.0' = {
  name: 'dep-saLogs-${location}'
  params: {
    name: storageAccountName
    location: location

    kind: 'StorageV2'
    skuName: 'Standard_LRS'

    allowSharedKeyAccess: false
    publicNetworkAccess: 'Enabled'

    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        userAssignedIdentity.id
      ]
    }

    allowCrossTenantReplication: false

    fileServices: {
      shareDeleteRetentionPolicy: {
        allowPermanentDelete: true
        enabled: false
      }
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
    }

      supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'

    managementPolicyRules: [
      {
        definition: {
          actions: {
            baseBlob: {
              delete: {
                daysAfterModificationGreaterThan: 180
              }
            }
          }
          filters: {
            blobTypes: ['blockBlob', 'appendBlob']
            prefixMatch: ['']
          }
        }
        enabled: true
        name: 'Cleanup after 180 days'
        type: 'Lifecycle'
      }
    ]
  }
}

module logsRoleAssignments './logs-role-assignments.bicep' = {
  name: 'dep-logsRoleAssignments-${location}'
  params: {
    storageAccountResourceId: saLogs.outputs.resourceId
    userAssignedIdentityPrincipalId: userAssignedIdentity.properties.principalId
  }
}

output resourceId string = saLogs.outputs.resourceId
output name string = saLogs.outputs.name

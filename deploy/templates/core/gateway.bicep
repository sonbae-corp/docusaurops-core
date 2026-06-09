@description('Name of the Application Gateway')
param appGatewayName string

@description('Location where the Application Gateway will be deployed')
param location string

@description('SKU name for the Application Gateway')
param skuName string = 'Standard_v2'

@description('Capacity (instance count) for the Application Gateway')
param skuCapacity int = 1

@description('Enable autoscale for the Application Gateway')
param enableAutoscale bool = false

@description('Autoscale minimum instance count for the Application Gateway')
param autoscaleMinCapacity int = 1

@description('Autoscale maximum instance count for the Application Gateway')
param autoscaleMaxCapacity int = 10

@description('Name for the root backend pool (e.g. "root")')
param rootBackendName string

@description('Probe path for the root backend health check')
param rootProbePath string

@description('Resource ID of the subnet where the endpoint needs to be created for this resource.')
param subnetResourceId string = ''

@description('Resource ID of the public IP address. When empty, no public frontend IP configuration is added.')
param publicIpResourceId string

@description('SSL certificate name')
param sslCertificateName string = ''

@secure()
@description('Base64-encoded PFX certificate data')
param sslCertificateData string = ''

@secure()
@description('Password for the PFX certificate')
param sslCertificatePassword string = ''

@description('Enable HTTP/2 protocol')
param enableHttp2 bool = true

@description('Enable FIPS mode')
param enableFIPS bool = false

@description('Additional backend address pools to preserve (e.g. from existing site deployments)')
param additionalBackendAddressPools array = []

@description('Additional path rules to preserve in the URL path map (e.g. from existing site deployments)')
param additionalPathRules array = []

@description('Additional backend HTTP settings to preserve (e.g. from existing site deployments)')
param additionalBackendHttpSettings array = []

@description('Additional health probes to preserve (e.g. from existing site deployments)')
param additionalProbes array = []

@description('Resource ID of the Log Analytics workspace for diagnostic settings')
param logAnalyticsWorkspaceResourceId string = ''

var appGatewayResourceId = resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Network/applicationGateways', appGatewayName)
var defaultBackendSettingName = 'defaultbackendsetting'
var publicFrontendIpName = 'appGwPublicFrontendIpIPv4'
var httpsPortName = 'port_443'
var httpPortName = 'port_80'
var listenerName = 'listener'
var mainRuleName = 'mainrule'
var sslCertAvailable = !empty(sslCertificateName) && !empty(sslCertificateData)

module appGateway 'br/public:avm/res/network/application-gateway:0.9.0' = {
  params: {
    name: appGatewayName
    location: location
    availabilityZones: [1, 2, 3]
    sku: skuName
    autoscaleMinCapacity: enableAutoscale ? autoscaleMinCapacity : -1
    autoscaleMaxCapacity: enableAutoscale ? autoscaleMaxCapacity : -1
    capacity: skuCapacity
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetResourceId
          }
        }
      }
    ]
    sslCertificates: sslCertAvailable ? [
      {
        name: sslCertificateName
        properties: {
          data: sslCertificateData
          password: sslCertificatePassword
        }
      }
    ] : []
    frontendIPConfigurations: [
      ...(!empty(publicIpResourceId) ? [
        {
          name: publicFrontendIpName
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            publicIPAddress: {
              id: publicIpResourceId
            }
          }
        }
      ] : [])
    ]
    frontendPorts: [
      ...(sslCertAvailable ? [
        {
          name: httpsPortName
          properties: {
            port: 443
          }
        }
      ] : [
        {
          name: httpPortName
          properties: {
            port: 80
          }
        }
      ])
    ]
    backendAddressPools: [
      {
        name: rootBackendName
        properties: {
          backendAddresses: []
        }
      }
      ...additionalBackendAddressPools
    ]
    backendHttpSettingsCollection: [
      {
        name: defaultBackendSettingName
        id: '${appGatewayResourceId}/backendHttpSettingsCollection/${defaultBackendSettingName}'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Enabled'
          pickHostNameFromBackendAddress: true
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 60
          probe: {
            id: '${appGatewayResourceId}/probes/azurewebsitesprobe'
          }
        }
      }
      ...additionalBackendHttpSettings
    ]
    httpListeners: sslCertAvailable ? [
      {
        name: listenerName
        id: '${appGatewayResourceId}/httpListeners/${listenerName}'
        properties: {
          frontendIPConfiguration: {
            id: '${appGatewayResourceId}/frontendIPConfigurations/${publicFrontendIpName}'
          }
          frontendPort: {
            id: '${appGatewayResourceId}/frontendPorts/${httpsPortName}'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${appGatewayResourceId}/sslCertificates/${sslCertificateName}'
          }
          hostNames: []
          requireServerNameIndication: false
          customErrorConfigurations: []
        }
      }
    ] : [
      {
        name: listenerName
        properties: {
          frontendIPConfiguration: {
            id: '${appGatewayResourceId}/frontendIPConfigurations/${publicFrontendIpName}'
          }
          frontendPort: {
            id: '${appGatewayResourceId}/frontendPorts/${httpPortName}'
          }
          protocol: 'Http'
        }
      }
    ]
    urlPathMaps: [
      {
        name: mainRuleName
        properties: {
          defaultBackendAddressPool: {
            id: '${appGatewayResourceId}/backendAddressPools/${rootBackendName}'
          }
          defaultBackendHttpSettings: {
            id: '${appGatewayResourceId}/backendHttpSettingsCollection/${defaultBackendSettingName}'
          }
          pathRules: [
            {
              name: rootBackendName
              id: '${appGatewayResourceId}/urlPathMaps/${mainRuleName}/pathRules/${rootBackendName}'
              properties: {
                paths: [
                  '/*'
                ]
                backendAddressPool: {
                  id: '${appGatewayResourceId}/backendAddressPools/${rootBackendName}'
                }
                backendHttpSettings: {
                  id: '${appGatewayResourceId}/backendHttpSettingsCollection/${defaultBackendSettingName}'
                }
              }
            }
            ...additionalPathRules
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: mainRuleName
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 100
          httpListener: {
            id: '${appGatewayResourceId}/httpListeners/${listenerName}'
          }
          urlPathMap: {
            id: '${appGatewayResourceId}/urlPathMaps/${mainRuleName}'
          }
        }
      }
    ]
    probes: [
      {
        name: 'azurewebsitesprobe'
        id: '${appGatewayResourceId}/probes/azurewebsitesprobe'
        properties: {
          protocol: 'Https'
          path: rootProbePath
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          match: {
            statusCodes: [
              '200-403'
            ]
          }
        }
      }
      ...additionalProbes
    ]
    enableHttp2: enableHttp2
    enableFips: enableFIPS
    diagnosticSettings: !empty(logAnalyticsWorkspaceResourceId) ? [
      {
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
      }
    ] : []
  }
}

@description('Resource ID of the created Application Gateway')
output appGatewayId string = appGateway.outputs.resourceId

@description('Resource name of the created Application Gateway')
output appGatewayName string = appGateway.outputs.name

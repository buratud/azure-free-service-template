param location string
param containerName string
@secure()
param secret object
param registry array
@secure()
param env object
param image string

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${containerName}-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource managedEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${containerName}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: workspace.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      { name: 'Consumption', workloadProfileType: 'Consumption' }
    ]
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerName
  location: location
  properties: {
    environmentId: managedEnv.id
    configuration: {
      secrets: secret.value
      registries: registry
      activeRevisionsMode: 'Single'
    }
    template: {
      containers: [
        {
          name: containerName
          image: image
          command: []
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
          env: env.value
        }
      ]
      scale: {maxReplicas:1, minReplicas:1}
    }
    workloadProfileName: 'Consumption'
  }
}

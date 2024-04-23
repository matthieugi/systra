param prefix string
var location = 'francecentral'

resource logicAppsPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${prefix}-logicapp-plan'
  location: location
  kind: 'elastic'
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
    size: 'WS1'
    family: 'WS'
  }
}

resource logicApps 'Microsoft.Web/sites@2022-03-01' = {
  name: '${prefix}-logicapp'
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: logicAppsPlan.id
    siteConfig:{
      appSettings:[
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
   }
  }
}

resource logicAppsBinding 'Microsoft.Web/sites/hostNameBindings@2023-01-01' = {
  parent: logicApps
  name: '${logicApps.name}.azurewebsites.net'
  properties:{
    siteName: logicApps.name
    hostNameType: 'Verified'
  }
}

resource logicAppsConfig 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: logicApps
  name: 'web'
  properties: {
    use32BitWorkerProcess: false
    netFrameworkVersion: 'v6.0'
    publicNetworkAccess: 'Enabled'

    cors: {
      supportCredentials: false
    }
  }
}

resource translator 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: '${prefix}-translator'
  location: location
  kind: 'TextTranslation'
  sku: {
    name: 'S1'
  }
}

resource stt 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: '${prefix}-stt'
  location: location
  kind: 'SpeechServices'
  sku: {
    name: 'S0'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${prefix}storagesystra'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'default'
  properties: {
    publicAccess: 'None'
  }
}

resource eventGrid 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' = {
  name: '${prefix}-eventgrid'
  location: location
  properties: {
    source: storageAccount.id
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

resource cosmosdb 'Microsoft.DocumentDB/databaseAccounts@2024-02-15-preview' = {
  name: '${prefix}-cosmosdb'
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    databaseAccountOfferType: 'Standard' 
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
  }
}

resource cosmosdbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-11-15' = {
  parent: cosmosdb
  name: 'workshop'
  properties: {
    resource: {
      id: 'workshop'
    }
  }
}

resource cosmosdbCollection 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  parent: cosmosdbDatabase
  name: 'results'
  properties: {
    resource:{
      id: 'results'
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
    
    }
    indexingPolicy: {
      automatic: true
      indexingMode: 'consistent'
      includedPaths: [
        {
          path: '/*'
        }
      ]
    }
  }
}

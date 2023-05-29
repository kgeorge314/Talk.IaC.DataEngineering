@description('Azure Region use Get-AzLocation for a full list')
param AzureRegion string = resourceGroup().location

@description('The optional environment this state is for')
param Environment string = 'Shared'

@description('The AAD Tenant Id')
param TenantId string 

@description('AAD ObjectIds that need access to the TF resources')
param ObjectIds array 

@description('SPN DisplayName')
param SPNName string

@description('SPN Secret')
@secure()
param SPNSecret string

@description('SPN Secret Expiry UnixTime')
param SPNSecretExpiry int



var stateStorageAccountName = 'tf${uniqueString(resourceGroup().id)}'
var stateStorageAccountContainerName = 'tf-state'
var stateKeyVault = 'tf-kv-${uniqueString(resourceGroup().id)}'

var roleDefinitionIds = loadJsonContent('_referenceData/Data.Azure.Roles.json')
var roleStorageBlobDataContributorId = string(first(filter(roleDefinitionIds, r => r.Name == 'Storage Blob Data Contributor')).Id)
var roleStorageBlobDataContributorRoleDefinitionId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${roleStorageBlobDataContributorId}'

//Subscription shared-infrastructure storage account
 resource tfStateStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: stateStorageAccountName
  location: AzureRegion
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
  }
  tags: {
    Environment: Environment
    Location: AzureRegion
    Purpose: 'Storage account to store Terraform state and other shared resources'
  }
}

resource tfStateStorageAccountBlobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: tfStateStorageAccount
  name: 'default'

  properties: {
    deleteRetentionPolicy: {
      days: 30
      enabled: true
    }
    containerDeleteRetentionPolicy: {
      days: 30
      enabled: true
    }
  }
}

resource tfStateStorageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  parent: tfStateStorageAccountBlobService
  name: stateStorageAccountContainerName
}

resource tfStateStorageAccountRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for objectId in ObjectIds: {
  name: guid('${tfStateStorageAccount.id}${objectId}')
  properties: {
    principalId: objectId
    roleDefinitionId: roleStorageBlobDataContributorRoleDefinitionId
  }
}]

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: stateKeyVault
  location: AzureRegion
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: TenantId
    accessPolicies: [for objectId in ObjectIds: {
      tenantId: TenantId
      objectId: objectId
      permissions: {
        secrets: [
          'list'
          'get'
          'set'
        ]
      }
    }]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource secretAADSpn 'Microsoft.KeyVault/vaults/secrets@2023-02-01' ={
  parent: keyVault
  name: 'AADSpnSecret'
  properties:{
    value: SPNSecret
    contentType: SPNName
    attributes: {
      enabled:true
      exp:SPNSecretExpiry
    }
  }
}

output tf_state_storage_account_name string = tfStateStorageAccount.name
output tf_state_storage_account_container_name string = tfStateStorageAccountContainer.name

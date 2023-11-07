targetScope = 'resourceGroup'

param location string = resourceGroup().location
param cycleVm string
param adminUsername string
@secure()
param adminPublicKey string
@secure()
param adminPassword string
param storageAccountName string
param storageContainerName string
param logsUri string

var script = loadTextContent('cycleInstall.sh')

resource cycleInstall 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: '${cycleVm}/cycleInstall'
  location: location
  properties: {
    asyncExecution: false
    outputBlobUri: '${logsUri}/cycle_install_stdout.txt'
    errorBlobUri: '${logsUri}/cycle_install_stderr.txt'
    parameters: [
      {
        name: 'AZURE_SUBSCRIPTION_ID'
        value: subscription().subscriptionId
      }
      {
        name: 'AZURE_TENANT_ID'
        value: subscription().subscriptionId
      }
      {
        name: 'CYCLECLOUD_ADMIN_NAME'
        value: adminUsername
      }
      {
        name: 'CYCLECLOUD_LOCATION'
        value: location
      }
      {
        name: 'CYCLECLOUD_RESOURCE_GROUP'
        value: resourceGroup().name
      }
      {
        name: 'CYCLECLOUD_STORAGE_ACCOUNT'
        value: storageAccountName
      }
      {
        name: 'CYCLECLOUD_STORAGE_CONTAINER'
        value: storageContainerName
      }
      {
        name: 'CYCLECLOUD_SUBSCRIPTION_NAME'
        value: subscription().displayName
      }
    ]
    protectedParameters: [
      {
        name: 'CYCLECLOUD_ADMIN_PASSWORD'
        value: adminPassword
      }
      {
        name: 'CYCLECLOUD_ADMIN_PUBLIC_KEY'
        value: adminPublicKey
      }
    ]
    source: {
      script: script
    }
  }
}

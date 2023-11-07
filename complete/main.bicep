targetScope = 'subscription'

param resourceGroupName string
param location string = deployment().location
param cidr string = '10.181.0.0/24'
param adminUsername string
@secure()
param adminPublicKey string
@secure()
param adminPassword string
param peeredVnetName string
param peeredResourceGroupName string


var cycleVmName = 'cycleVm'
var vnetName = 'cyclevnet'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}


module vnet './modules/vnet.bicep' = {
  scope: rg
  name: 'vnet'
  params: {
    location: location
    vnetName: vnetName
    cidr: cidr
    peeredResourceGroupName: peeredResourceGroupName
    peeredVnetName: peeredVnetName
  }
}

module cycleVm './modules/cycleVm.bicep' = {
  scope: rg
  name: 'cycleVm'
  params: {
    location: location
    vmName: cycleVmName
    adminUsername: adminUsername
    adminPublicKey: adminPublicKey
    subnetId: vnet.outputs.subnetId
  }
}

var storageAccountName = 'sa${uniqueString(subscription().subscriptionId, resourceGroupName)}x'
module storage './modules/storage.bicep' = {
  scope: rg
  name: 'storage'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

module roleAssignmentSub './modules/roleAssignmentsSub.bicep' = {
  scope: subscription()
  name: 'roleAssignmentSub'
  params: {
    principalId: cycleVm.outputs.cycleManagedIdentity
  }
  dependsOn: [
    rg
  ]
}
module roleAssignmentRg './modules/roleAssignmentsRg.bicep' = {
  scope: rg
  name: 'roleAssignmentRg'
  params: {
    principalId: cycleVm.outputs.cycleManagedIdentity
  }
}

module cycleInstall './modules/cycleInstall.bicep' = {
  scope: rg
  name: 'cycleInstall'
  params: {
    location: location
    cycleVm: cycleVmName
    adminUsername: adminUsername
    adminPassword: adminPassword
    adminPublicKey: adminPublicKey
    storageAccountName: storageAccountName
    storageContainerName: 'cyclecloud'
    logsUri: '${storage.outputs.blobEndpoint}logs'
  }
  dependsOn: [
    roleAssignmentRg
    roleAssignmentSub
  ]
}

module peering './modules/peering.bicep' = {
  name: 'peerFrom${peeredVnetName}'
  scope: resourceGroup(peeredResourceGroupName)
  params: {
    name: '${resourceGroupName}_${vnetName}'
    vnetName: peeredVnetName
    allowGateway: true
    vnetId: vnet.outputs.vnetId
  }
}



@description('The resource ID for the managed identity to be used by the VM')
param managedIdentityId string
@description('The resource ID for the subnet to be used by the VM')
param subnetId string
param vmName string = 'autocycle'
@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2204'
@description('The size of the VM')
param vmSize string = 'Standard_D2s_v3'

var imageReference = {
  'Ubuntu-1804': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2004': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}

// all the parameters that will be put in the userdata script
param azure_subscription_id string = subscription().subscriptionId
param azure_tenant_id string = subscription().tenantId
param cyclecloud_admin_name string
@secure()
param cyclecloud_admin_password string
param cyclecloud_admin_public_key string
param cyclecloud_location string = resourceGroup().location
param cyclecloud_resource_group string = resourceGroup().name
param cyclecloud_storage_account string
param cyclecloud_storage_container string
param cyclecloud_subscription_name string = subscription().displayName


var userdata = base64(
  replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      loadTextContent('user-data.sh'), 'AZURE_SUBSCRIPTION_ID', azure_subscription_id
                    ), 'AZURE_TENANT_ID', azure_tenant_id
                  ), 'CYCLECLOUD_ADMIN_NAME', cyclecloud_admin_name
                ), 'CYCLECLOUD_ADMIN_PASSWORD', cyclecloud_admin_password
              ), 'CYCLECLOUD_ADMIN_PUBLIC_KEY', cyclecloud_admin_public_key
            ), 'CYCLECLOUD_LOCATION', cyclecloud_location
          ), 'CYCLECLOUD_RESOURCE_GROUP', cyclecloud_resource_group
        ), 'CYCLECLOUD_STORAGE_ACCOUNT', cyclecloud_storage_account
      ), 'CYCLECLOUD_STORAGE_CONTAINER', cyclecloud_storage_container
    ), 'CYCLECLOUD_SUBSCRIPTION_NAME', cyclecloud_subscription_name
  )
)

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${vmName}-nic'
  location: cyclecloud_location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName
  location: cyclecloud_location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: imageReference[ubuntuOSVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: cyclecloud_admin_name
      customData: userdata
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${cyclecloud_admin_name}/.ssh/authorized_keys'
              keyData: cyclecloud_admin_public_key
            }
          ]
        }
      }
    }
  }
}

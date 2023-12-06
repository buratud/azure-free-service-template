param location string

param username string
@secure()
param publicKey string
param rgName string
param vmSize string = 'Standard_B1s'
param deleteWithVm bool = true
param imageRef object
param diskSizeGb int = 64

param vnetName string = '${rgName}-vnet'
param nicName string = '${rgName}-nic'
param nsgName string = '${rgName}-nsg'
param publicIpName string = '${rgName}-ip'
param vmName string = rgName
param osDiskName string = '${rgName}-osdisk'
param vmHostName string = rgName

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.1.0.0/16' ]
    }
    subnets: [
      { name: 'default', properties: { addressPrefix: '10.1.1.0/24' } }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: []
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[1].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
            properties: {
              deleteOption: deleteWithVm ? 'Delete' : 'Detach'
            }
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: diskSizeGb
        deleteOption: deleteWithVm ? 'Delete' : 'Detach'
      }
      imageReference: imageRef
    }
    networkProfile: {
      networkInterfaces: [ {
          id: nic.id
          properties: {
            deleteOption: deleteWithVm ? 'Delete' : 'Detach'
          }
        }
      ]
    }
    osProfile: {
      computerName: vmHostName
      adminUsername: username
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${username}/.ssh/authorized_keys'
              keyData: publicKey
            }
          ]
        }
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  }
}

output ip string = nic.properties.ipConfigurations[0].properties.privateIPAddress

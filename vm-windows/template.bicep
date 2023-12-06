param location string

param username string
@secure()
param password string
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

resource windowsIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource windowsNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: []
  }
}

resource windowsNic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: windowsIp.id
            properties: {
              deleteOption: deleteWithVm ? 'Delete' : 'Detach'
            }
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: windowsNsg.id
    }
  }

}

resource windowsVm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
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
      networkInterfaces: [
        {
          id: windowsNic.id
          properties: {
            deleteOption: deleteWithVm ? 'Delete' : 'Detach'
          }
        }
      ]
    }
    osProfile: {
      computerName: vmHostName
      adminUsername: username
      adminPassword: password
      windowsConfiguration: {
        enableVMAgentPlatformUpdates: true
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: true
          patchMode: 'AutomaticByPlatform'
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

output ip string = windowsNic.properties.ipConfigurations[0].properties.privateIPAddress

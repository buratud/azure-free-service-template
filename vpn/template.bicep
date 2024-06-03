param location string
param ipName string
param vnetName string
param vnetGatewayName string
param subnetAddrPrefix string

resource ip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: ipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: 'GatewaySubnet'
  properties: {
    addressPrefix: subnetAddrPrefix
  }
}

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = {
  name: vnetGatewayName
  location: location
  properties: {
    gatewayType: 'Vpn'
    ipConfigurations: [
      {
        name: 'default'
        properties: { privateIPAllocationMethod: 'Dynamic', publicIPAddress: {id: ip.id}, subnet: {id: subnet.id} }
      }
    ]
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
    sku: {name: 'VpnGw1', tier: 'VpnGw1'}
  }
}

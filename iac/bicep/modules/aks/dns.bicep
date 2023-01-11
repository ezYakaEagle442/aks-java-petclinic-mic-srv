@description('The location of the Azure resources.')
param location string = resourceGroup().location

param vnetName string = 'vnet-aks'

@description('AKS Cluster API server IP')
param aksIp string

param dnsZone string = 'cloudapp.azure.com'
param appDnsZone string = 'kissmyapp.${location}.${dnsZone}'
param customDns string = 'javaonazurehandsonlabs.com'
param privateDnsZone string = 'privatelink.${location}.azmk8s.io'


resource aksPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZone
  location: 'global'  // /!\ 'global' instead of '${location}'. This is because Azure DNS is a global service. otherwise you will hit this error:"MissingRegistrationForLocation. "The subscription is not registered for the resource type 'privateDnsZones' in the location 'westeurope' 
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing =  {
  name: vnetName
}
output vnetId string = vnet.id

resource DnsVNetLinklnkaks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'dns-vnet-lnk-aks-petclinic'
  location: 'global'  // /!\ 'global' instead of '${location}'. This is because Azure DNS is a global service.
  parent: aksPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}
output private_dns_link_id string = DnsVNetLinklnkaks.id

resource aksAppsRecordSet 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '*'
  parent: aksPrivateDnsZone
  properties: {
    aRecords: [
      {
        ipv4Address: aksIp // AksLb.properties.frontendIPConfigurations[0].properties.privateIPAddress
      }
    ]
    ttl: 360
  }
}

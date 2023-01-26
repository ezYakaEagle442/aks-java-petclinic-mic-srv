@description('The location of the Azure resources.')
param location string = resourceGroup().location

param vnetName string = 'vnet-aks'

@description('Petclinic service LB IP')
param aksSvcIp string

param recordSetA string = 'petclinic'
param dnsZone string = 'cloudapp.azure.com'
param appDnsZone string = 'petclinic.${location}.${dnsZone}'
param customDns string = 'javaonazurehandsonlabs.com'
param privateDnsZone string = 'privatelink.${location}.azmk8s.io' // API-server URL ex for public clusters: appinnojava-478b2e1b.hcp.westeurope.azmk8s.io


resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing =  {
  name: vnetName
}
output vnetId string = vnet.id

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/dnszones?pivots=deployment-language-bicep
resource aksDnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: dnsZone
  location: 'global'  // /!\ 'global' instead of '${location}'. This is because Azure DNS is a global service. otherwise you will hit this error:"MissingRegistrationForLocation. "The subscription is not registered for the resource type 'privateDnsZones' in the location 'westeurope' 
  properties: {
    zoneType: 'Public'
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/dnszones/a?pivots=deployment-language-bicep

resource RecordSetA 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  name: recordSetA
  parent: aksDnsZone
  properties: {
    ARecords: [
      {
        ipv4Address: aksSvcIp
      }
    ]
    TTL: 360
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/dnszones/cname?pivots=deployment-language-bicep
resource aksAppsRecordSetCname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  name: 'www'
  parent: aksDnsZone
  properties: {
    CNAMERecord: {
      cname: 'www.${appDnsZone}'
    }
    TTL: 360    
  }
}


// https://docs.microsoft.com/en-us/azure/templates/microsoft.network/publicipaddresses?tabs=bicep#publicipaddresssku
// /!\ The Ingress Controller Public IP is created in the Managed RG
/*
resource pip 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'kubernetes-a98d45b5e0e944693bee66077c873e5f'
  location: location
  sku: {
    name: 'Standard' // https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static' // Standard IP must be STATIC
    deleteOption: 'Delete'
    dnsSettings: {
      domainNameLabel: 'petclinic'
      fqdn: appDnsZone
    }
  }
}
output pipId string = pip.id
output pipGUID string = pip.properties.resourceGuid
output pipAddress string = pip.properties.ipAddress
*/

/*
resource aksPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZone
  location: 'global'  // /!\ 'global' instead of '${location}'. This is because Azure DNS is a global service. otherwise you will hit this error:"MissingRegistrationForLocation. "The subscription is not registered for the resource type 'privateDnsZones' in the location 'westeurope' 
}

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
*/

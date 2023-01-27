/*
# https://docs.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns#delegate-the-domain
# In the registrar's DNS management page, edit the NS records and replace the NS records with the Azure DNS name servers.

ns_server=$(az network dns record-set ns show --resource-group $rg_name --zone-name $app_dns_zone --name @ --query nsRecords[0] --output tsv)
ns_server_length=$(echo -n $ns_server | wc -c)
ns_server="${ns_server:0:$ns_server_length-1}"
echo "Name Server" $ns_server

To test DNS resolution:
# /!\ On your windows station , flush DNS ... : ipconfig /flushdns
# Mac: sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; say cache flushed
# on WSL : sudo apt-get install dbus
# /etc/init.d/dbus start
# Ubuntu : sudo /etc/init.d/dns-clean restart or sudo systemd-resolve --flush-caches
# ps ax | grep dnsmasq
# sudo /etc/init.d/dnsmasq restart
nslookup $app_dns_zone $ns_server

*/


@description('The location of the Azure resources.')
param location string = resourceGroup().location

param vnetName string = 'vnet-aks'

@description('Petclinic service LB IP')
param aksSvcIp string

@allowed([
  'azure'
  'custom'
])
param dnsZoneType string = 'azure'

param recordSetA string = '@'
param cloudappDnsZone string = 'cloudapp.azure.com'
param appDnsZone string = 'petclinic.${location}.${cloudappDnsZone}'
param customDns string = 'javaonazurehandsonlabs.com'
param privateDnsZone string = 'privatelink.${location}.azmk8s.io' // API-server URL ex for public clusters: appinnojava-478b2e1b.hcp.westeurope.azmk8s.io


resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing =  {
  name: vnetName
}
output vnetId string = vnet.id

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/dnszones?pivots=deployment-language-bicep
resource azureDnsZone 'Microsoft.Network/dnsZones@2018-05-01' = if(dnsZoneType=='azure') {
  name: appDnsZone
  location: 'global'  // /!\ 'global' instead of '${location}'. This is because Azure DNS is a global service. otherwise you will hit this error:"MissingRegistrationForLocation. "The subscription is not registered for the resource type 'privateDnsZones' in the location 'westeurope' 
  properties: {
    zoneType: 'Public'
  }
}
resource cutomDnsZone 'Microsoft.Network/dnsZones@2018-05-01' = if(dnsZoneType=='custom') {
  name: customDns
  location: 'global'  // /!\ 'global' instead of '${location}'. This is because Azure DNS is a global service. otherwise you will hit this error:"MissingRegistrationForLocation. "The subscription is not registered for the resource type 'privateDnsZones' in the location 'westeurope' 
  properties: {
    zoneType: 'Public'
  }
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/dnszones/a?pivots=deployment-language-bicep

resource RecordSetA 'Microsoft.Network/dnsZones/A@2018-05-01' = if(dnsZoneType=='azure') {
  name: recordSetA
  parent: azureDnsZone
  properties: {
    ARecords: [
      {
        ipv4Address: aksSvcIp
      }
    ]
    TTL: 360
  }
}

resource RecordSetAForCustomDNS 'Microsoft.Network/dnsZones/A@2018-05-01' = if(dnsZoneType=='custom') {
  name: recordSetA
  parent: cutomDnsZone
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
resource RecordSetCname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = if(dnsZoneType=='azure') {
  name: 'home'
  parent: azureDnsZone
  properties: {
    CNAMERecord: {
      cname: 'www.${appDnsZone}'
    }
    TTL: 360    
  }
}

resource RecordSetCnameForCustomDNS 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = if(dnsZoneType=='custom') {
  name: 'home'
  parent: cutomDnsZone
  properties: {
    CNAMERecord: {
      cname: 'www.${customDns}'
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

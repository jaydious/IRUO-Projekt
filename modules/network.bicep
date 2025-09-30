// modules/network.bicep - FIXED SSH access
param location string
param environment string

// Subnetovi
var subnets = [
  {
    name: 'subnet-jump'
    properties: {
      addressPrefix: '10.0.1.0/24'
    }
  }
  {
    name: 'subnet-marko-maric'
    properties: {
      addressPrefix: '10.0.10.0/24'
    }
  }
  {
    name: 'subnet-ante-antic'
    properties: {
      addressPrefix: '10.0.20.0/24'
    }
  }
  {
    name: 'subnet-ivo-ivic'
    properties: {
      addressPrefix: '10.0.30.0/24'
    }
  }
]

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-cloudlearn-${environment}'
  location: location
  tags: {
    course: 'test'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: subnets
  }
}

// Network Security Groups - DOPUSTI SSH SVIma
resource nsgMarko 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-marko-maric'
  location: location
  tags: {
    course: 'test'
    user: 'marko.maric'
    role: 'instruktor'
  }
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-From-Any'
        properties: {
          description: 'Allow SSH access from anywhere'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-HTTP-From-Any'
        properties: {
          description: 'Allow HTTP from anywhere'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nsgAnte 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-ante-antic'
  location: location
  tags: {
    course: 'test'
    user: 'ante.antic'
    role: 'student'
  }
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-From-Any'
        properties: {
          description: 'Allow SSH access from anywhere'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nsgIvo 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-ivo-ivic'
  location: location
  tags: {
    course: 'test'
    user: 'ivo.ivic'
    role: 'student'
  }
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-From-Any'
        properties: {
          description: 'Allow SSH access from anywhere'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-HTTP-From-Any'
        properties: {
          description: 'Allow HTTP from anywhere'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Public IP for Jump Host - STANDARD SKU
resource jumpPublicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'pip-jump-${environment}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {
    course: 'test'
  }
}

// Outputs
output vnetName string = vnet.name
output vnetId string = vnet.id
output subnetRefs array = [
  {
    name: 'subnet-jump'
    id: '${vnet.id}/subnets/subnet-jump'
  }
  {
    name: 'subnet-marko-maric' 
    id: '${vnet.id}/subnets/subnet-marko-maric'
  }
  {
    name: 'subnet-ante-antic'
    id: '${vnet.id}/subnets/subnet-ante-antic'
  }
  {
    name: 'subnet-ivo-ivic'
    id: '${vnet.id}/subnets/subnet-ivo-ivic'
  }
]
output nsgRefs array = [
  {
    userName: 'marko.maric'
    nsgName: nsgMarko.name
    nsgId: nsgMarko.id
    role: 'instruktor'
  }
  {
    userName: 'ante.antic'
    nsgName: nsgAnte.name
    nsgId: nsgAnte.id
    role: 'student'
  }
  {
    userName: 'ivo.ivic'
    nsgName: nsgIvo.name
    nsgId: nsgIvo.id
    role: 'student'
  }
]
output jumpPublicIPId string = jumpPublicIP.id
// modules/compute.bicep - SMANJENO na 3 VM-a
param location string
param environment string
param subnetRefs array
param nsgRefs array
param adminUsername string = 'azureuser'
@secure()
param adminPassword string

// Public IP za Jump Host - STANDARD SKU
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

// Network Interfaces
resource nicMarkoJump 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'nic-marko-maric-jump'
  location: location
  tags: {
    course: 'test'
    user: 'marko.maric'
    type: 'jump-host'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRefs[0].id
          }
          publicIPAddress: {
            id: jumpPublicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgRefs[0].nsgId
    }
  }
}

resource nicAnteJump 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'nic-ante-antic-jump'
  location: location
  tags: {
    course: 'test'
    user: 'ante.antic'
    type: 'jump-host'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRefs[0].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgRefs[1].nsgId
    }
  }
}

resource nicIvoWeb 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'nic-ivo-ivic-web'
  location: location
  tags: {
    course: 'test'
    user: 'ivo.ivic'
    type: 'wordpress'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetRefs[3].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgRefs[2].nsgId
    }
  }
}

// VM-ovi - SAMO 3 (zbog quota)
resource vmMarkoJump 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'vm-marko-maric-jump'
  location: location
  tags: {
    course: 'test'
    user: 'marko.maric'
    role: 'instruktor'
    type: 'jump-host'
    environment: environment
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'  // SMANJENO na B1s (1 vCPU)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 32
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        caching: 'ReadWrite'
      }
      dataDisks: [
        {
          createOption: 'Empty'
          lun: 0
          diskSizeGB: 32
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
      ]
    }
    osProfile: {
      computerName: 'vm-marko-jump'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicMarkoJump.id
        }
      ]
    }
  }
}

resource vmAnteJump 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'vm-ante-antic-jump'
  location: location
  tags: {
    course: 'test'
    user: 'ante.antic'
    role: 'student'
    type: 'jump-host'
    environment: environment
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'  // SMANJENO na B1s (1 vCPU)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 32
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        caching: 'ReadWrite'
      }
      dataDisks: [
        {
          createOption: 'Empty'
          lun: 0
          diskSizeGB: 32
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
      ]
    }
    osProfile: {
      computerName: 'vm-ante-jump'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicAnteJump.id
        }
      ]
    }
  }
}

resource vmIvoWeb 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'vm-ivo-ivic-web'
  location: location
  tags: {
    course: 'test'
    user: 'ivo.ivic'
    role: 'student'
    type: 'wordpress'
    environment: environment
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'  // SMANJENO na B1s (1 vCPU)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 32
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        caching: 'ReadWrite'
      }
      dataDisks: [
        {
          createOption: 'Empty'
          lun: 0
          diskSizeGB: 32
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
      ]
    }
    osProfile: {
      computerName: 'vm-ivo-web'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicIvoWeb.id
        }
      ]
    }
  }
}

// Custom Script Extension za WordPress setup
resource wpExtensionIvo 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  parent: vmIvoWeb
  name: 'wordpress-setup'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/application-workloads/wordpress/wordpress-single-vm-ubuntu/install_wordpress.sh'
      ]
      commandToExecute: 'bash install_wordpress.sh'
    }
  }
}

// Outputs
output vmIds array = [
  vmMarkoJump.id
  vmAnteJump.id
  vmIvoWeb.id
]
output vmNames array = [
  vmMarkoJump.name
  vmAnteJump.name
  vmIvoWeb.name
]
output jumpHostIP string = jumpPublicIP.properties.ipAddress
output wordpressVM string = vmIvoWeb.name
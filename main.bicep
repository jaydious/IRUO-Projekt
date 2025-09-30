// main.bicep - POJEDNOSTAVLJENO za studentsku pretplatu
targetScope = 'subscription'

param location string = 'westeurope'
param environment string = 'test'
@secure()
param adminPassword string

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-cloudlearn-${environment}'
  location: location
  tags: {
    course: 'test'
    environment: environment
    project: 'cloudlearn'
    deployment: 'bicep'
  }
}

// Networking Module
module network 'modules/network.bicep' = {
  name: 'network-deployment'
  scope: rg
  params: {
    location: location
    environment: environment
  }
}

// Storage Module
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  scope: rg
  params: {
    location: location
    environment: environment
  }
}

// Compute Module - SMANJENO na 3 VM-a
module compute 'modules/compute.bicep' = {
  name: 'compute-deployment'
  scope: rg
  params: {
    location: location
    environment: environment
    subnetRefs: network.outputs.subnetRefs
    nsgRefs: network.outputs.nsgRefs
    adminPassword: adminPassword
  }
}

// Outputs
output resourceGroupName string = rg.name
output networkInfo object = network.outputs
output computeInfo object = compute.outputs
output storageInfo object = storage.outputs
output deploymentSummary string = 'CloudLearn environment deployed successfully with 3 VMs (due to student quota limits)'
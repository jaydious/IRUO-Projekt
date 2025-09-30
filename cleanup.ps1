# cleanup.ps1 - CloudLearn Azure Cleanup Script
param(
    [string]$Environment = "test"
)

Write-Host "=== CloudLearn Azure Cleanup ===" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor White

$ResourceGroup = "rg-cloudlearn-$Environment"

# Check if resource group exists
Write-Host "`nChecking resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup

if ($rgExists -eq "true") {
    Write-Host "Resource group $ResourceGroup exists. Deleting..." -ForegroundColor Red
    
    # Get resources before deletion for logging
    Write-Host "`nResources to be deleted:" -ForegroundColor Yellow
    az resource list --resource-group $ResourceGroup --output table
    
    # Delete resource group
    az group delete --name $ResourceGroup --yes --no-wait
    
    Write-Host "`nResource group deletion initiated..." -ForegroundColor Green
    Write-Host "This may take several minutes to complete." -ForegroundColor Gray
    Write-Host "Check status with: az group list --output table" -ForegroundColor Gray
    
} else {
    Write-Host "Resource group $ResourceGroup does not exist." -ForegroundColor Green
}

# Clean up any stray resources
Write-Host "`nCleaning up stray resources..." -ForegroundColor Yellow

# Delete any VMs not in resource groups
$strayVMs = az vm list --query "[?resourceGroup==null].name" --output tsv
foreach ($vm in $strayVMs) {
    Write-Host "Deleting stray VM: $vm" -ForegroundColor Red
    az vm delete --name $vm --yes --no-wait
}

# Delete any VNets not in resource groups  
$strayVNets = az network vnet list --query "[?resourceGroup==null].name" --output tsv
foreach ($vnet in $strayVNets) {
    Write-Host "Deleting stray VNet: $vnet" -ForegroundColor Red
    az network vnet delete --name $vnet --yes
}

Write-Host "`n=== Cleanup completed! ===" -ForegroundColor Green
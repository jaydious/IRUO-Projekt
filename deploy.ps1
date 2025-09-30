# deploy.ps1 - FIXED s adminPassword parametrom
param(
    [string]$Location = "westeurope",
    [string]$Environment = "test",
    [string]$AdminPassword = "Password123!"
)

Write-Host "=== CloudLearn Azure Deployment ===" -ForegroundColor Green
Write-Host "Location: $Location"
Write-Host "Environment: $Environment"
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray

# Check Azure login
Write-Host "`nChecking Azure login..." -ForegroundColor Yellow
$account = az account show | ConvertFrom-Json
if (-not $account) {
    Write-Host "Please login to Azure first: az login" -ForegroundColor Red
    exit 1
}
Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "Subscription: $($account.name)" -ForegroundColor Green

# Cleanup previous deployment
Write-Host "`nCleaning up previous deployment..." -ForegroundColor Yellow
$ResourceGroup = "rg-cloudlearn-$Environment"
az group delete --name $ResourceGroup --yes --no-wait 2>$null
Start-Sleep -Seconds 10

# Validate Bicep template
Write-Host "`nValidating Bicep template..." -ForegroundColor Yellow
az bicep build --file "main.bicep"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Bicep validation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Bicep validation passed!" -ForegroundColor Green

# Deploy Bicep template
Write-Host "`nStarting deployment..." -ForegroundColor Yellow
$DeploymentName = "cloudlearn-deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

az deployment sub create `
    --location $Location `
    --template-file "main.bicep" `
    --parameters "environment=$Environment" "adminPassword=$AdminPassword" `
    --name $DeploymentName

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=== Deployment completed successfully! ===" -ForegroundColor Green
    
    # Get deployment outputs
    Write-Host "`n=== Deployment Outputs ===" -ForegroundColor Cyan
    $outputs = az deployment sub show --name $DeploymentName --query properties.outputs --output json | ConvertFrom-Json
    Write-Host "Resource Group: $($outputs.resourceGroupName.value)" -ForegroundColor White
    
    # List created resources
    Write-Host "`n=== Created Resources ===" -ForegroundColor Cyan
    az resource list --resource-group "rg-cloudlearn-$Environment" --output table
    
    # Cost estimation
    Write-Host "`n=== Cost Estimation ===" -ForegroundColor Yellow
    Write-Host "Estimated monthly cost: ~$350-450 (Standard SKU je skuplji)" -ForegroundColor White
    Write-Host "VM Count: 6 x Standard_B2s" -ForegroundColor White
    Write-Host "Public IPs: 2 x Standard SKU" -ForegroundColor White
    Write-Host "Students Credit: $100 (lasts ~5-7 days)" -ForegroundColor Magenta
    
} else {
    Write-Host "`n=== Deployment failed! ===" -ForegroundColor Red
    Write-Host "Check errors above and run cleanup.ps1 before retrying" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Clean up: .\cleanup.ps1 -Environment $Environment" -ForegroundColor White
Write-Host "2. Check resources in Azure Portal" -ForegroundColor White
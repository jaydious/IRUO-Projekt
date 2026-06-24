<#
.SYNOPSIS
    TechSprint - jedinstvena deployment skripta (PowerShell).

.DESCRIPTION
    Prima putanju do .csv datoteke (ime;prezime;rola) i u JEDNOM pokretanju
    kreira kompletnu izoliranu okolinu za varijabilan broj korisnika na
    odabranom oblaku (OpenStack i/ili Azure). Skripta se pokrece jednom -
    Terraform-ov for_each nad CSV-om kreira sve resurse.

    Validacija CSV-a se radi prije poziva Terraforma. Sam deployment se NE
    izvodi ako se preda parametar -PlanOnly (terraform plan umjesto apply).

.PARAMETER CsvPath
    Putanja do CSV datoteke s korisnicima.

.PARAMETER Cloud
    Ciljani oblak: openstack | azure | both (zadano: both).

.PARAMETER PlanOnly
    Ako je postavljeno, izvodi 'terraform plan' (bez stvarne izgradnje).

.EXAMPLE
    .\deploy.ps1 -CsvPath ..\scripts\users.csv -Cloud azure
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [ValidateSet("openstack", "azure", "both")]
    [string]$Cloud = "both",

    [switch]$PlanOnly
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

function Test-Csv {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "CSV datoteka nije pronadena: $Path"
    }

    $lines = Get-Content -Path $Path | Where-Object { $_.Trim() -ne "" }
    if ($lines.Count -lt 2) {
        throw "CSV mora imati zaglavlje i barem jednog korisnika."
    }

    $header = $lines[0].Trim()
    if ($header -ne "ime;prezime;rola") {
        throw "Neispravno zaglavlje. Ocekivano 'ime;prezime;rola', dobiveno '$header'."
    }

    $devops = 0
    $devs = 0
    foreach ($line in $lines[1..($lines.Count - 1)]) {
        $cols = $line.Split(";")
        if ($cols.Count -ne 3) {
            throw "Neispravan redak (ocekivane 3 kolone): '$line'"
        }
        switch ($cols[2].Trim().ToLower()) {
            "devops_lead" { $devops++ }
            "developer"   { $devs++ }
            default       { throw "Nepoznata rola '$($cols[2])' u retku: '$line'" }
        }
    }

    Write-Host "[OK] CSV validan: $devs programer(a), $devops voditelj(a)." -ForegroundColor Green
}

function Invoke-Terraform {
    param([string]$Dir, [string]$Csv)

    Push-Location $Dir
    try {
        Write-Host "==> terraform init ($Dir)" -ForegroundColor Cyan
        terraform init -input=false

        $action = if ($PlanOnly) { "plan" } else { "apply" }
        $extra  = if ($PlanOnly) { @() } else { @("-auto-approve") }

        Write-Host "==> terraform $action ($Dir)" -ForegroundColor Cyan
        terraform $action -input=false -var "users_csv=$Csv" @extra
    }
    finally {
        Pop-Location
    }
}

# --- 1) Validacija ulaza ---
$CsvFull = (Resolve-Path $CsvPath).Path
Test-Csv -Path $CsvFull

# --- 2) Deployment po odabranom oblaku (jedan apply po oblaku) ---
if ($Cloud -in @("openstack", "both")) {
    Invoke-Terraform -Dir (Join-Path $root "terraform\openstack") -Csv $CsvFull
}
if ($Cloud -in @("azure", "both")) {
    Invoke-Terraform -Dir (Join-Path $root "terraform\azure") -Csv $CsvFull
}

Write-Host "`n[GOTOVO] Okolina kreirana iz '$CsvFull' (cloud: $Cloud)." -ForegroundColor Green

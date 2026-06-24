###############################################################################
# provider.tf - Azure provideri i Terraform postavke
#
# Projekt: TechSprint - izolirane testne okoline za Moodle (Azure varijanta)
# Autor:   Juraj Herceg
#
# Autentikacija: koristi se Azure CLI sesija (az login) ili Service Principal
# preko okolinskih varijabli (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID,
# ARM_SUBSCRIPTION_ID). Kredencijali se NE drze u kodu.
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {
  # Tenant se preuzima iz az login sesije; po potrebi navesti tenant_id.
}

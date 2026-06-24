###############################################################################
# provider.tf  - OpenStack provider and Terraform settings
#
# Projekt: TechSprint - izolirane testne okoline za Moodle
# Autor:   Juraj Herceg
#
# Napomena: kredencijali se NE drže u kodu. Provider cita standardne
# OpenStack RC varijable okruzenja (OS_AUTH_URL, OS_USERNAME, OS_PASSWORD,
# OS_PROJECT_NAME, OS_USER_DOMAIN_NAME, OS_REGION_NAME ...) koje se ucitavaju
# iz "openrc" datoteke (source openrc.sh) prije pokretanja Terraforma.
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Provider se autenticira preko cloud-admin korisnika (uloga "admin") jer
# Terraform kreira odvojene projekte/tenante i korisnike za svakog programera.
provider "openstack" {
  # Sve vrijednosti dolaze iz okolinskih varijabli (clouds.yaml / openrc).
  # Eksplicitno navodimo samo region radi citljivosti.
  region = var.region
}

###############################################################################
# terraform.tfvars - vrijednosti specificne za okolinu (uredite po potrebi)
#
# Pokretanje (jednom): az login && terraform init && terraform apply
###############################################################################

subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "westeurope"

users_csv  = "../../scripts/users.csv"
aad_domain = "techsprintexample.onmicrosoft.com"

vm_size       = "Standard_B2s"  # 2 vCPU / 4 GB (zahtjev projekta)
infra_vm_size = "Standard_B1ms" # DevOps Lead VM

os_disk_size_gb   = 32
data_disk_size_gb = 32

admin_username      = "azureadmin"
ssh_public_key_path = "~/.ssh/techsprint_id_rsa.pub"

# Management Group hijerarhija je opcionalna (trazi prava na tenant root group).
create_management_group = false

common_tags = {
  project     = "techsprint"
  environment = "testing"
}

name_prefix = "ts-tst"

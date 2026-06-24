###############################################################################
# terraform.tfvars - vrijednosti specificne za okolinu (uredite po potrebi)
#
# Pokretanje (jednom): source openrc.sh && terraform init && terraform apply
###############################################################################

region                = "RegionOne"
users_csv             = "../../scripts/users.csv"
external_network_name = "public"
dns_servers           = ["1.1.1.1", "8.8.8.8"]

# Cloud image i flavori (uskladiti s nazivima u vasem OpenStack katalogu).
image_name   = "Rocky-9-GenericCloud"
flavor_app   = "m1.medium" # 2 vCPU / 4 GB RAM (zahtjev projekta)
flavor_infra = "m1.small"  # jump host + lead VM

os_disk_size_gb   = 20
data_disk_size_gb = 20

ssh_public_key_path = "~/.ssh/techsprint_id_rsa.pub"

# Za demo se moze ostaviti 0.0.0.0/0; u produkciji ograniciti na ured/VPN.
admin_cidr = "0.0.0.0/0"

common_tags = {
  project     = "techsprint"
  environment = "testing"
}

name_prefix = "ts-tst"

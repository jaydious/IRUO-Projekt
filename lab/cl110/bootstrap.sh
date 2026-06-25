#!/usr/bin/env bash
###############################################################################
# bootstrap.sh - priprema Red Hat Academy CL110-16.1 laba za OpenStack deploy
#
# Pokrenuti iz korijena kloniranog repoa NA workstationu, s vec sourceanim
# admin-rc (prompt pokazuje (admin)):
#     source ~/admin-rc
#     git clone https://github.com/jaydious/IRUO-Projekt.git
#     cd IRUO-Projekt && bash lab/cl110/bootstrap.sh
#
# Radi:
#  1) instalira terraform u ~/bin (lab nema terraform, ali ima internet)
#  2) generira SSH kljuc techsprint_id_rsa
#  3) kreira mali flavor 'ts.smoke' (lab overcloud ima ~5 GB slobodnog RAM-a)
#  4) generira terraform/openstack/cl110.auto.tfvars prilagodjen labu
#  5) terraform init (povlaci OpenStack provider)
###############################################################################
set -euo pipefail

TF_VERSION="1.9.8"
BIN="$HOME/bin"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$BIN"

echo "== 1) terraform =="
if [ ! -x "$BIN/terraform" ] && ! command -v terraform >/dev/null 2>&1; then
  curl -fsSL -o /tmp/tf.zip \
    "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
  unzip -o /tmp/tf.zip -d "$BIN" >/dev/null
fi
grep -q 'HOME/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH=$HOME/bin:$PATH' >> "$HOME/.bashrc"
export PATH="$BIN:$PATH"
terraform -version | head -1

echo "== 2) SSH kljuc =="
[ -f "$HOME/.ssh/techsprint_id_rsa" ] || \
  ssh-keygen -t rsa -b 2048 -N '' -f "$HOME/.ssh/techsprint_id_rsa" >/dev/null
echo "kljuc: $HOME/.ssh/techsprint_id_rsa(.pub)"

echo "== 3) mali flavor ts.smoke (1 vCPU / 768 MB / 10 GB) =="
if ! openstack flavor show ts.smoke >/dev/null 2>&1; then
  openstack flavor create ts.smoke --vcpus 1 --ram 768 --disk 10 >/dev/null
fi
openstack flavor show ts.smoke -f value -c name -c ram -c vcpus -c disk

echo "== 3b) snizi rhel8 min_ram na 768 (lab ima ~5 GB slobodnog RAM-a) =="
# rhel8 image ima min_ram 2048; lab nema dovoljno RAM-a za vise 2 GB instanci.
# Snizavamo min_ram da bi 768 MB flavor bio prihvacen (reverzibilno: --min-ram 2048).
openstack image set rhel8 --min-ram 768 || true
openstack image show rhel8 -f value -c min_ram -c name

echo "== 4) cl110.auto.tfvars =="
REGION="${OS_REGION_NAME:-regionOne}"
cat > "$REPO_ROOT/terraform/openstack/cl110.auto.tfvars" <<TFV
# Auto-generirano za Red Hat Academy CL110-16.1 lab (override terraform.tfvars)
region                = "${REGION}"
users_csv             = "../../scripts/users-smoke.csv"
external_network_name = "provider-datacentre"
dns_servers           = ["172.25.250.254"]
image_name            = "rhel8"
flavor_app            = "ts.smoke"
flavor_infra          = "ts.smoke"
os_disk_size_gb       = 10
data_disk_size_gb     = 5
ssh_public_key_path   = "~/.ssh/techsprint_id_rsa.pub"
admin_cidr            = "0.0.0.0/0"
# Lab: provider kreira Nova instance u admin projektu, pa Neutron resurse drzimo
# u admin projektu (inace "Port not usable for instance"). Izolacija ostaje
# zasebnim mrezama/security grupama; Keystone projekti/role i dalje se kreiraju.
use_tenant_isolation  = false
# Octavia u ovom labu ne uspije finalizirati amphoru (context deadline exceeded),
# pa za cist prolaz preskacemo LB. LB je u dizajnu zadano ukljucen (vidi varijablu).
enable_loadbalancer   = false
# Manila backend u CL110 labu (CephFS) zavrsi share u 'error' stanju, pa ga za
# cist prolaz preskacemo. Datotecna pohrana je u dizajnu zadano ukljucena (NFS).
enable_file_share     = false
share_proto           = "CEPHFS"
common_tags = {
  project     = "techsprint"
  environment = "testing"
}
name_prefix = "ts-tst"
TFV
echo "zapisano: terraform/openstack/cl110.auto.tfvars (region=${REGION})"

echo "== 5) terraform init =="
cd "$REPO_ROOT/terraform/openstack"
terraform init -input=false

echo ""
echo "[OK] Bootstrap gotov. Sljedece:"
echo "  export PATH=\$HOME/bin:\$PATH"
echo "  cd $REPO_ROOT/terraform/openstack"
echo "  terraform plan"

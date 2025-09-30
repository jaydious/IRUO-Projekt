#!/bin/bash
#
# CloudLearn Status Script
# Displays current deployment status and resource information
#

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_header() { echo -e "${BLUE}=== $1 ===${NC}"; }

log_header "CLOUDLEARN DEPLOYMENT STATUS"

echo "=== VIRTUAL MACHINES ==="
openstack server list --sort-column Name

echo -e "\n=== NETWORKS ==="
openstack network list --sort-column Name

echo -e "\n=== SECURITY GROUPS ==="
openstack security group list --sort-column Name

echo -e "\n=== VOLUMES ==="
openstack volume list --sort-column Name

echo -e "\n=== FLOATING IPs ==="
openstack floating ip list

log_info "Status check completed"

# Show jump host IPs for access
echo -e "\n=== JUMP HOST ACCESS IPs ==="
openstack server list -c Name -c Networks -f value | grep jump-vm
#!/bin/bash
#
# CloudLearn Cleanup Script
# Safely removes all CloudLearn resources from OpenStack
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=== CLOUDLEARN RESOURCE CLEANUP ==="
echo -n "Are you sure you want to delete ALL CloudLearn resources? (y/N): "
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    log_info "Deleting VMs..."
    openstack server list -f value -c Name | grep -E "(marko.maric|ante.antic|ivo.ivic)-" | xargs -r openstack server delete
    
    sleep 10
    
    log_info "Deleting volumes..."
    openstack volume list -f value -c Name | grep -E "(marko.maric|ante.antic|ivo.ivic)-.*-disk2" | xargs -r openstack volume delete
    
    log_info "Deleting routers..."
    openstack router list -f value -c Name | grep -E "router-(marko.maric|ante.antic|ivo.ivic)" | while read router; do
        openstack router unset --external-gateway "$router" 2>/dev/null || true
        openstack router delete "$router"
    done
    
    log_info "Deleting networks..."
    openstack network list -f value -c Name | grep -E "net-(marko.maric|ante.antic|ivo.ivic)" | xargs -r openstack network delete
    
    log_info "Deleting security groups..."
    openstack security group list -f value -c Name | grep -E "sg-(marko.maric|ante.antic|ivo.ivic)-" | xargs -r openstack security group delete
    
    log_info "Cleaning up floating IPs..."
    openstack floating ip list -f value -c "Floating IP Address" | xargs -r openstack floating ip delete
    
    log_info "Cleanup completed!"
else
    log_info "Cleanup cancelled"
fi
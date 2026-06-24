###############################################################################
# outputs.tf - korisne izlazne vrijednosti nakon deploymenta
###############################################################################

output "jump_host_public_ip" {
  description = "Javni (floating) IP jump hosta - jedina javna tocka ulaza."
  value       = openstack_networking_floatingip_v2.jump.address
}

output "devops_lead_private_ip" {
  description = "Privatna adresa DevOps Lead VM-a u hub mrezi."
  value       = "10.0.0.11"
}

output "developer_projects" {
  description = "Mapa programer -> ID Keystone projekta (tenanta)."
  value       = { for k, p in openstack_identity_project_v3.dev : k => p.id }
}

output "moodle_loadbalancer_vips" {
  description = "VIP adresa load balancera po programeru (ulaz u Moodle)."
  value       = { for k, lb in openstack_lb_loadbalancer_v2.moodle : k => lb.vip_address }
}

output "moodle_node_ips" {
  description = "Privatne adrese Moodle cvorova po programeru."
  value       = { for k, n in local.moodle_nodes : k => n.ip }
}

output "object_storage_containers" {
  description = "Naziv Swift kontejnera (objektna pohrana) po programeru."
  value       = { for k, c in openstack_objectstorage_container_v1.moodle : k => c.name }
}

output "file_share_export_locations" {
  description = "NFS export lokacije Manila shareova (datotecna pohrana)."
  value       = { for k, s in openstack_sharedfilesystem_share_v2.backup : k => s.export_locations }
}

output "ssh_access_hint" {
  description = "Primjer pristupa: SSH preko jump hosta do Moodle cvora."
  value       = "ssh -J rocky@${openstack_networking_floatingip_v2.jump.address} rocky@<moodle_private_ip>"
}

###############################################################################
# outputs.tf - korisne izlazne vrijednosti (Azure)
###############################################################################

output "bastion_public_ip" {
  description = "Javni IP Azure Bastiona - jedina javna tocka ulaza (null ako je Bastion iskljucen)."
  value       = one(azurerm_public_ip.bastion[*].ip_address)
}

output "devops_lead_vm" {
  description = "Naziv DevOps Lead VM-a (pristup preko Bastiona)."
  value       = azurerm_linux_virtual_machine.lead.name
}

output "developer_resource_groups" {
  description = "Mapa programer -> naziv resource grupe."
  value       = { for k, rg in azurerm_resource_group.dev : k => rg.name }
}

output "moodle_lb_private_ips" {
  description = "Privatni frontend IP load balancera po programeru."
  value = {
    for k, lb in azurerm_lb.moodle :
    k => lb.frontend_ip_configuration[0].private_ip_address
  }
}

output "storage_accounts" {
  description = "Naziv storage accounta po programeru (Blob + Files)."
  value       = { for k, sa in azurerm_storage_account.dev : k => sa.name }
}

output "moodle_vm_names" {
  description = "Nazivi Moodle VM-ova."
  value       = { for k, vm in azurerm_linux_virtual_machine.moodle : k => vm.name }
}

output "developer_upns" {
  description = "User Principal Name svakog kreiranog korisnika."
  value       = { for k, u in azuread_user.all : k => u.user_principal_name }
}

###############################################################################
# rbac.tf - Entra ID (Azure AD) korisnici/grupe iz CSV-a + RBAC (least-privilege)
#
#  - Korisnici se kreiraju iz CSV-a i smjestaju u grupe prema roli.
#  - Programeri: CUSTOM rola "TechSprint VM Operator" (start/restart/deallocate
#    + read) ISKLJUCIVO na VLASTITOJ resource grupi -> upravljaju samo svojim VM.
#  - Voditelj: ugradena "Virtual Machine Contributor" na svim dev RG-ovima +
#    hub RG (upravljanje svim VM-ovima) i "Reader" na razini pretplate.
#
# NAPOMENA: kreiranje AAD korisnika/grupa ovisi o var.enable_aad_users. Kada je
# false (npr. studentski racun bez tenant-admin ovlasti), AAD dio se preskace, a
# custom rola se demonstrira dodjelom prijavljenom korisniku (vidi dno datoteke).
###############################################################################

data "azurerm_subscription" "current" {}
data "azuread_client_config" "current" {}

locals {
  aad_principals = var.enable_aad_users ? merge(local.developers, local.leads) : {}
}

# ------------------------------- KORISNICI ---------------------------------
resource "random_password" "aad_user" {
  for_each = local.aad_principals
  length   = 24
  special  = true
}

resource "azuread_user" "all" {
  for_each = local.aad_principals

  user_principal_name   = "${each.value.username}@${var.aad_domain}"
  display_name          = "${each.value.ime} ${each.value.prezime}"
  mail_nickname         = replace(each.value.username, ".", "")
  password              = random_password.aad_user[each.key].result
  force_password_change = true
}

# -------------------------------- GRUPE ------------------------------------
resource "azuread_group" "developers" {
  count            = var.enable_aad_users ? 1 : 0
  display_name     = "grp-${var.name_prefix}-developers"
  security_enabled = true
}

resource "azuread_group" "devops_leads" {
  count            = var.enable_aad_users ? 1 : 0
  display_name     = "grp-${var.name_prefix}-devops-leads"
  security_enabled = true
}

resource "azuread_group_member" "developers" {
  for_each = var.enable_aad_users ? local.developers : {}

  group_object_id  = azuread_group.developers[0].object_id
  member_object_id = azuread_user.all[each.key].object_id
}

resource "azuread_group_member" "devops_leads" {
  for_each = var.enable_aad_users ? local.leads : {}

  group_object_id  = azuread_group.devops_leads[0].object_id
  member_object_id = azuread_user.all[each.key].object_id
}

# --------------------- CUSTOM ROLA ZA PROGRAMERE ---------------------------
# Definicija custom role kreira se uvijek (vlasnik pretplate ima ovlasti).
resource "azurerm_role_definition" "vm_operator" {
  name        = "TechSprint VM Operator (${var.name_prefix})"
  scope       = data.azurerm_subscription.current.id
  description = "Start/Restart/Deallocate i citanje VM-ova - bez izmjene/brisanja."

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/instanceView/read",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/loadBalancers/read",
    ]
    not_actions = []
  }

  assignable_scopes = [data.azurerm_subscription.current.id]
}

# Programer dobiva custom rolu ISKLJUCIVO na svojoj resource grupi.
resource "azurerm_role_assignment" "dev_vm_operator" {
  for_each = var.enable_aad_users ? local.developers : {}

  scope              = azurerm_resource_group.dev[each.key].id
  role_definition_id = azurerm_role_definition.vm_operator.role_definition_resource_id
  principal_id       = azuread_user.all[each.key].object_id
}

# ----------------------- ULOGE ZA VODITELJA (LEAD) -------------------------
# Voditelj: VM Contributor na svakom dev RG-u (paljenje/gasenje svih VM-ova).
resource "azurerm_role_assignment" "lead_vm_contributor_dev" {
  for_each = var.enable_aad_users ? {
    for pair in setproduct(keys(local.leads), keys(local.developers)) :
    "${pair[0]}__${pair[1]}" => { lead = pair[0], dev = pair[1] }
  } : {}

  scope                = azurerm_resource_group.dev[each.value.dev].id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_user.all[each.value.lead].object_id
}

# Voditelj: VM Contributor i na hub RG-u (Lead VM, Bastion).
resource "azurerm_role_assignment" "lead_vm_contributor_hub" {
  for_each = var.enable_aad_users ? local.leads : {}

  scope                = azurerm_resource_group.hub.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_user.all[each.key].object_id
}

# Voditelj: Reader na razini pretplate (pregled cijele okoline).
resource "azurerm_role_assignment" "lead_reader_sub" {
  for_each = var.enable_aad_users ? local.leads : {}

  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azuread_user.all[each.key].object_id
}

# ------------------ DEMONSTRACIJA (kada AAD korisnici nisu dostupni) --------
# Kada enable_aad_users=false, custom rola se dodjeljuje prijavljenom korisniku
# na hub resource grupi - dokaz da je custom RBAC rola ispravno definirana i
# dodjeljiva, bez potrebe za kreiranjem novih korisnika u imeniku.
resource "azurerm_role_assignment" "demo_vm_operator_signed_in" {
  count = var.enable_aad_users ? 0 : 1

  scope              = azurerm_resource_group.hub.id
  role_definition_id = azurerm_role_definition.vm_operator.role_definition_resource_id
  principal_id       = data.azuread_client_config.current.object_id
}

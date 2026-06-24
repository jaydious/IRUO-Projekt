###############################################################################
# resource_groups.tf - logicna hijerarhija Resource Grupa (+ opc. Mgmt Group)
#
# Hijerarhija:
#   (opc.) Management Group  mg-techsprint
#     └─ Subscription
#         ├─ rg-ts-tst-hub          (dijeljeno: Bastion, mreza-hub, Lead VM)
#         └─ rg-ts-tst-dev-<ime>    (po programeru: VM, mreza, storage, LB)
###############################################################################

# Opcionalna Management Group hijerarhija (zahtijeva prava na tenant root group).
resource "azurerm_management_group" "techsprint" {
  count        = var.create_management_group ? 1 : 0
  display_name = "mg-techsprint"
  name         = "mg-techsprint"

  subscription_ids = [var.subscription_id]
}

# Dijeljena (hub) resource grupa.
resource "azurerm_resource_group" "hub" {
  name     = "rg-${var.name_prefix}-hub"
  location = var.location
  tags     = var.common_tags
}

# Resource grupa po programeru -> jasna izolacija i scope za RBAC.
resource "azurerm_resource_group" "dev" {
  for_each = local.developers

  name     = "rg-${var.name_prefix}-dev-${each.key}"
  location = var.location
  tags     = merge(var.common_tags, { owner = each.key })
}

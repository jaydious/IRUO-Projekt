###############################################################################
# network.tf - VNet izolacija (hub + VNet po programeru) i peering
#
# Izolacija:
#  - Svaki programer ima VLASTITI VNet (10.<10+idx>.0.0/16). VNetovi programera
#    NISU medusobno peerani -> programeri se ne vide.
#  - Hub VNet je peeran s VNetom svakog programera (oba smjera) -> Lead VM i
#    Azure Bastion iz huba dosezu sve dev VM-ove.
#  - Javni IP postoji ISKLJUCIVO na Azure Bastionu (vidi bastion.tf).
###############################################################################

# ------------------------------- HUB VNET ----------------------------------
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.name_prefix}-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  address_space       = [local.hub_cidr]
  tags                = var.common_tags
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet" # obvezan naziv za Azure Bastion
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_bastion_cidr]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "snet-${var.name_prefix}-mgmt"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.hub_mgmt_cidr]
}

# --------------------------- VNET PO PROGRAMERU ----------------------------
resource "azurerm_virtual_network" "dev" {
  for_each = local.developers

  name                = "vnet-${var.name_prefix}-${each.key}"
  resource_group_name = azurerm_resource_group.dev[each.key].name
  location            = azurerm_resource_group.dev[each.key].location
  address_space       = [local.vnet_cidr[each.key]]
  tags                = merge(var.common_tags, { owner = each.key })
}

resource "azurerm_subnet" "app" {
  for_each = local.developers

  name                 = "snet-${var.name_prefix}-app-${each.key}"
  resource_group_name  = azurerm_resource_group.dev[each.key].name
  virtual_network_name = azurerm_virtual_network.dev[each.key].name
  address_prefixes     = [local.snet_cidr[each.key]]

  # Service endpoint za Storage -> promet prema storage accountu ostaje na Azure backboneu.
  service_endpoints = ["Microsoft.Storage"]
}

# ------------------------------- PEERING -----------------------------------
resource "azurerm_virtual_network_peering" "hub_to_dev" {
  for_each = local.developers

  name                      = "peer-hub-to-${each.key}"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.dev[each.key].id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "dev_to_hub" {
  for_each = local.developers

  name                      = "peer-${each.key}-to-hub"
  resource_group_name       = azurerm_resource_group.dev[each.key].name
  virtual_network_name      = azurerm_virtual_network.dev[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

# NAT Gateway za izlaz dev instanci na Internet (preuzimanje paketa),
# bez dodjele javnih IP-ova pojedinim VM-ovima.
resource "azurerm_public_ip" "nat" {
  for_each = local.developers

  name                = "pip-${var.name_prefix}-nat-${each.key}"
  resource_group_name = azurerm_resource_group.dev[each.key].name
  location            = azurerm_resource_group.dev[each.key].location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(var.common_tags, { owner = each.key })
}

resource "azurerm_nat_gateway" "dev" {
  for_each = local.developers

  name                = "nat-${var.name_prefix}-${each.key}"
  resource_group_name = azurerm_resource_group.dev[each.key].name
  location            = azurerm_resource_group.dev[each.key].location
  sku_name            = "Standard"
  tags                = merge(var.common_tags, { owner = each.key })
}

resource "azurerm_nat_gateway_public_ip_association" "dev" {
  for_each = local.developers

  nat_gateway_id       = azurerm_nat_gateway.dev[each.key].id
  public_ip_address_id = azurerm_public_ip.nat[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "dev" {
  for_each = local.developers

  subnet_id      = azurerm_subnet.app[each.key].id
  nat_gateway_id = azurerm_nat_gateway.dev[each.key].id
}

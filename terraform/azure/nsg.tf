###############################################################################
# nsg.tf - Network Security Groups + Application Security Groups (po programeru)
#
# ASG grupira Moodle NIC-ove logicki; NSG pravila referenciraju ASG umjesto
# fiksnih IP-ova (citljivije i otpornije na promjene adresa).
###############################################################################

resource "azurerm_application_security_group" "moodle" {
  for_each = local.developers

  name                = "asg-${var.name_prefix}-moodle-${each.key}"
  resource_group_name = azurerm_resource_group.dev[each.key].name
  location            = azurerm_resource_group.dev[each.key].location
  tags                = merge(var.common_tags, { owner = each.key })
}

resource "azurerm_network_security_group" "app" {
  for_each = local.developers

  name                = "nsg-${var.name_prefix}-app-${each.key}"
  resource_group_name = azurerm_resource_group.dev[each.key].name
  location            = azurerm_resource_group.dev[each.key].location
  tags                = merge(var.common_tags, { owner = each.key })
}

# SSH dozvoljen samo iz hub mreze (Bastion + Lead VM), prema Moodle ASG.
resource "azurerm_network_security_rule" "ssh_from_hub" {
  for_each = local.developers

  name                        = "Allow-SSH-From-Hub"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = local.hub_cidr
  destination_application_security_group_ids = [azurerm_application_security_group.moodle[each.key].id]
  resource_group_name         = azurerm_resource_group.dev[each.key].name
  network_security_group_name = azurerm_network_security_group.app[each.key].name
}

# HTTP/HTTPS dozvoljen od Azure Load Balancera (health probe + promet).
resource "azurerm_network_security_rule" "http_from_lb" {
  for_each = local.developers

  name                        = "Allow-Web-From-LB"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "AzureLoadBalancer"
  destination_application_security_group_ids = [azurerm_application_security_group.moodle[each.key].id]
  resource_group_name         = azurerm_resource_group.dev[each.key].name
  network_security_group_name = azurerm_network_security_group.app[each.key].name
}

# Web promet unutar vlastitog VNeta (LB frontend -> backend).
resource "azurerm_network_security_rule" "http_intra_vnet" {
  for_each = local.developers

  name                        = "Allow-Web-Intra-VNet"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "VirtualNetwork"
  destination_application_security_group_ids = [azurerm_application_security_group.moodle[each.key].id]
  resource_group_name         = azurerm_resource_group.dev[each.key].name
  network_security_group_name = azurerm_network_security_group.app[each.key].name
}

# Eksplicitna zabrana svakog drugog ulaznog prometa s Interneta.
resource "azurerm_network_security_rule" "deny_internet_in" {
  for_each = local.developers

  name                        = "Deny-Internet-Inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.dev[each.key].name
  network_security_group_name = azurerm_network_security_group.app[each.key].name
}

resource "azurerm_subnet_network_security_group_association" "app" {
  for_each = local.developers

  subnet_id                 = azurerm_subnet.app[each.key].id
  network_security_group_id = azurerm_network_security_group.app[each.key].id
}

###############################################################################
# bastion.tf - Azure Bastion (jedini javni ulaz u okolinu)
#
# Azure Bastion pruza SSH/RDP pristup VM-ovima kroz Azure Portal/CLI bez
# javnih IP-ova na samim VM-ovima. Javni IP postoji ISKLJUCIVO na Bastionu,
# cime je zadovoljen zahtjev "javni IP iskljucivo na Jump hostu".
###############################################################################

resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "pip-${var.name_prefix}-bastion"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

resource "azurerm_bastion_host" "hub" {
  count               = var.enable_bastion ? 1 : 0
  name                = "bas-${var.name_prefix}-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku                 = "Standard"

  # Tunneling omogucuje "az network bastion ssh" do dev VM-ova preko peeringa.
  tunneling_enabled = true

  ip_configuration {
    name                 = "ipconf"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = var.common_tags
}

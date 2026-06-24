###############################################################################
# loadbalancer.tf - Azure Load Balancer (Standard, interni) po programeru
#
# Interni LB raspodjeljuje HTTP/HTTPS promet izmedu dva Moodle cvora unutar
# izoliranog VNeta. Frontend je privatni IP (bez javne izlozenosti); pristup
# ide kroz Bastion/Lead. Usporedba s Application Gatewayem je u dokumentaciji.
###############################################################################

resource "azurerm_lb" "moodle" {
  for_each = local.developers

  name                = "lb-${var.name_prefix}-${each.key}"
  resource_group_name = azurerm_resource_group.dev[each.key].name
  location            = azurerm_resource_group.dev[each.key].location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "feip-internal"
    subnet_id                     = azurerm_subnet.app[each.key].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.common_tags, { owner = each.key })
}

resource "azurerm_lb_backend_address_pool" "moodle" {
  for_each = local.developers

  name            = "bepool-moodle"
  loadbalancer_id = azurerm_lb.moodle[each.key].id
}

resource "azurerm_lb_probe" "http" {
  for_each = local.developers

  name            = "probe-http"
  loadbalancer_id = azurerm_lb.moodle[each.key].id
  protocol        = "Http"
  port            = 80
  request_path    = "/login/index.php"
  interval_in_seconds = 10
  number_of_probes    = 3
}

resource "azurerm_lb_rule" "http" {
  for_each = local.developers

  name                           = "rule-http"
  loadbalancer_id                = azurerm_lb.moodle[each.key].id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "feip-internal"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.moodle[each.key].id]
  probe_id                       = azurerm_lb_probe.http[each.key].id
  load_distribution              = "SourceIP"
}

resource "azurerm_lb_rule" "https" {
  for_each = local.developers

  name                           = "rule-https"
  loadbalancer_id                = azurerm_lb.moodle[each.key].id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "feip-internal"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.moodle[each.key].id]
  probe_id                       = azurerm_lb_probe.http[each.key].id
  load_distribution              = "SourceIP"
}

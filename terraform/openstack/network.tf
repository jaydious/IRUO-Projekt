###############################################################################
# network.tf - Neutron mreze (hub + izolirana mreza po programeru)
#
# Princip izolacije:
#  - Svaki programer ima VLASTITU mrezu/subnet/router u svom projektu
#    (tenant_id = projekt programera). Izmedu mreza programera NEMA peeringa
#    ni rute -> programeri se medusobno ne vide (zahtjev mrezne izolacije).
#  - Svaki router ima gateway na vanjskoj (public) mrezi -> SNAT izlaz na
#    Internet za preuzimanje paketa, BEZ floating IP-a na aplikacijskim VM-ovima.
#  - Hub mreza nosi jump host (jedini s javnim floating IP-om) i DevOps Lead VM.
#  - Jump host i Lead VM su "multi-homed": dobivaju dodatni port u SVAKOJ dev
#    mrezi (fiksne adrese .10 i .11) -> mogu SSH-ati u sve instance, dok dev
#    mreze ostaju izolirane jedna od druge.
###############################################################################

# Vanjska mreza (dohvat, ne kreira se) - izvor floating IP-ova i SNAT-a.
data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

# ----------------------------- HUB MREZA -----------------------------------
resource "openstack_networking_network_v2" "hub" {
  name           = "${var.name_prefix}-net-hub"
  tenant_id      = local.hub_tenant_id
  admin_state_up = true
  tags           = [for k, v in var.common_tags : "${k}=${v}"]
}

resource "openstack_networking_subnet_v2" "hub" {
  name            = "${var.name_prefix}-subnet-hub"
  tenant_id       = local.hub_tenant_id
  network_id      = openstack_networking_network_v2.hub.id
  cidr            = local.hub_cidr
  gateway_ip      = local.hub_gateway
  ip_version      = 4
  dns_nameservers = var.dns_servers
}

resource "openstack_networking_router_v2" "hub" {
  name                = "${var.name_prefix}-rtr-hub"
  tenant_id           = local.hub_tenant_id
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "hub" {
  router_id = openstack_networking_router_v2.hub.id
  subnet_id = openstack_networking_subnet_v2.hub.id
}

# ------------------------- MREZA PO PROGRAMERU ------------------------------
resource "openstack_networking_network_v2" "dev" {
  for_each = local.developers

  name           = "${var.name_prefix}-net-${each.key}"
  tenant_id      = local.dev_tenant_id[each.key]
  admin_state_up = true
  tags           = [for k, v in var.common_tags : "${k}=${v}"]
}

resource "openstack_networking_subnet_v2" "dev" {
  for_each = local.developers

  name            = "${var.name_prefix}-subnet-${each.key}"
  tenant_id       = local.dev_tenant_id[each.key]
  network_id      = openstack_networking_network_v2.dev[each.key].id
  cidr            = local.dev_cidrs[each.key]
  gateway_ip      = local.dev_gateway[each.key]
  ip_version      = 4
  dns_nameservers = var.dns_servers
}

# Router po programeru s gatewayem na vanjskoj mrezi (SNAT izlaz na Internet).
resource "openstack_networking_router_v2" "dev" {
  for_each = local.developers

  name                = "${var.name_prefix}-rtr-${each.key}"
  tenant_id           = local.dev_tenant_id[each.key]
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "dev" {
  for_each = local.developers

  router_id = openstack_networking_router_v2.dev[each.key].id
  subnet_id = openstack_networking_subnet_v2.dev[each.key].id
}

# --------------------- MULTI-HOMING JUMP HOST / LEAD ------------------------
# Dodatni port jump hosta u svakoj dev mrezi (fiksna adresa .10).
resource "openstack_networking_port_v2" "jump_in_dev" {
  for_each = local.developers

  name           = "${var.name_prefix}-port-jump-${each.key}"
  tenant_id      = local.dev_tenant_id[each.key]
  network_id     = openstack_networking_network_v2.dev[each.key].id
  admin_state_up = true

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.dev[each.key].id
    ip_address = local.bastion_ip_in_dev[each.key]
  }

  security_group_ids = [openstack_networking_secgroup_v2.jump.id]
}

# Dodatni port DevOps Lead VM-a u svakoj dev mrezi (fiksna adresa .11).
resource "openstack_networking_port_v2" "lead_in_dev" {
  for_each = local.developers

  name           = "${var.name_prefix}-port-lead-${each.key}"
  tenant_id      = local.dev_tenant_id[each.key]
  network_id     = openstack_networking_network_v2.dev[each.key].id
  admin_state_up = true

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.dev[each.key].id
    ip_address = local.lead_ip_in_dev[each.key]
  }

  security_group_ids = [openstack_networking_secgroup_v2.lead.id]
}

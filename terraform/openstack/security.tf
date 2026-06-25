###############################################################################
# security.tf - Neutron security grupe (odvojeno za jump, lead i dev role)
#
# Pravila slijede least-privilege:
#  - Jump host: javni SSH (po potrebi ogranicen na admin_cidr).
#  - Lead: SSH samo s jump hosta.
#  - Moodle (dev): SSH samo s fiksnih adresa jump hosta i lead VM-a (/32),
#                  HTTP/HTTPS samo unutar vlastite dev podmreze (LB VIP),
#                  promet medu dva Moodle cvora unutar podmreze (HA).
###############################################################################

# ------------------------------- JUMP HOST ---------------------------------
resource "openstack_networking_secgroup_v2" "jump" {
  name        = "${var.name_prefix}-sg-jump"
  description = "Security grupa za jump host (bastion) - jedini javni ulaz."
  tenant_id   = local.hub_tenant_id
  tags        = [for k, v in var.common_tags : "${k}=${v}"]
}

resource "openstack_networking_secgroup_rule_v2" "jump_ssh_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.admin_cidr
  security_group_id = openstack_networking_secgroup_v2.jump.id
  description        = "SSH ulaz na jump host."
}

# Napomena: Neutron svakoj security grupi automatski dodaje default egress
# pravilo (dozvoli sav izlazni promet), pa eksplicitno "allow all egress"
# pravilo nije potrebno i izaziva 409 Conflict. Izlaz je dakle dozvoljen po defaultu.

# ----------------------------- DEVOPS LEAD ---------------------------------
resource "openstack_networking_secgroup_v2" "lead" {
  name        = "${var.name_prefix}-sg-lead"
  description = "Security grupa za DevOps Lead VM."
  tenant_id   = local.hub_tenant_id
  tags        = [for k, v in var.common_tags : "${k}=${v}"]
}

resource "openstack_networking_secgroup_rule_v2" "lead_ssh_from_jump" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = local.hub_cidr
  security_group_id = openstack_networking_secgroup_v2.lead.id
  description        = "SSH na lead VM iskljucivo iz hub (jump host) mreze."
}

# (default egress pravilo dodaje Neutron automatski - vidi napomenu gore)

# ----------------------- MOODLE (PO PROGRAMERU) ----------------------------
resource "openstack_networking_secgroup_v2" "app" {
  for_each = local.developers

  name        = "${var.name_prefix}-sg-app-${each.key}"
  description = "Security grupa Moodle instanci programera ${each.key}."
  tenant_id   = local.dev_tenant_id[each.key]
  tags        = [for k, v in var.common_tags : "${k}=${v}"]
}

# SSH samo s jump hosta (.10) i lead VM-a (.11) te dev podmreze.
resource "openstack_networking_secgroup_rule_v2" "app_ssh_from_jump" {
  for_each = local.developers

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "${local.bastion_ip_in_dev[each.key]}/32"
  security_group_id = openstack_networking_secgroup_v2.app[each.key].id
  description        = "SSH s jump hosta."
}

resource "openstack_networking_secgroup_rule_v2" "app_ssh_from_lead" {
  for_each = local.developers

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "${local.lead_ip_in_dev[each.key]}/32"
  security_group_id = openstack_networking_secgroup_v2.app[each.key].id
  description        = "SSH s DevOps Lead VM-a."
}

# HTTP/HTTPS samo unutar vlastite dev podmreze (LB VIP -> clanovi poola).
resource "openstack_networking_secgroup_rule_v2" "app_http" {
  for_each = local.developers

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = local.dev_cidrs[each.key]
  security_group_id = openstack_networking_secgroup_v2.app[each.key].id
  description        = "HTTP od load balancera unutar dev podmreze."
}

resource "openstack_networking_secgroup_rule_v2" "app_https" {
  for_each = local.developers

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = local.dev_cidrs[each.key]
  security_group_id = openstack_networking_secgroup_v2.app[each.key].id
  description        = "HTTPS od load balancera unutar dev podmreze."
}

# (default egress pravilo dodaje Neutron automatski - vidi napomenu gore)

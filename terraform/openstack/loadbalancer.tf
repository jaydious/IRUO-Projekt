###############################################################################
# loadbalancer.tf - Octavia load balancer po programeru (visoka dostupnost)
#
# Raspodjeljuje HTTP promet izmedu dva Moodle cvora (round-robin) i provodi
# health-check; ako jedan cvor padne, promet ide na drugi -> simulacija HA.
###############################################################################

resource "openstack_lb_loadbalancer_v2" "moodle" {
  for_each = local.developers

  name          = "${var.name_prefix}-lb-${each.key}"
  vip_subnet_id = openstack_networking_subnet_v2.dev[each.key].id
  vip_address   = local.moodle_ips[each.key].vip
  tenant_id     = openstack_identity_project_v3.dev[each.key].id
  tags          = [for k, v in var.common_tags : "${k}=${v}"]
}

resource "openstack_lb_listener_v2" "http" {
  for_each = local.developers

  name            = "${var.name_prefix}-lsnr-${each.key}"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.moodle[each.key].id
}

resource "openstack_lb_pool_v2" "http" {
  for_each = local.developers

  name        = "${var.name_prefix}-pool-${each.key}"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.http[each.key].id
}

resource "openstack_lb_monitor_v2" "http" {
  for_each = local.developers

  name        = "${var.name_prefix}-hm-${each.key}"
  pool_id     = openstack_lb_pool_v2.http[each.key].id
  type        = "HTTP"
  url_path    = "/login/index.php"
  expected_codes = "200,302"
  delay       = 10
  timeout     = 5
  max_retries = 3
}

# Clanovi poola = dva Moodle cvora svakog programera.
resource "openstack_lb_member_v2" "moodle" {
  for_each = local.moodle_nodes

  name          = "${var.name_prefix}-mbr-${each.key}"
  pool_id       = openstack_lb_pool_v2.http[each.value.dev].id
  address       = each.value.ip
  protocol_port = 80
  subnet_id     = openstack_networking_subnet_v2.dev[each.value.dev].id
}

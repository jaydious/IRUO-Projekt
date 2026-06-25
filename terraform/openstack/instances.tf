###############################################################################
# instances.tf - Nova instance: jump host, DevOps Lead VM, Moodle cvorovi
#
# NAPOMENA o vlasnistvu instanci:
#  Neutron resursi (mreze, portovi, security grupe, LB) kreiraju se izravno u
#  projektu programera preko atributa tenant_id. Nova/Cinder nemaju ekvivalent
#  pa se aplikacijske instance vezu na tenant mreze programera i scope-aju
#  metapodatcima/imenovanjem. Kontrola "samo svoji VM-ovi" osigurana je
#  project-scoped rolom "member" iz iam.tf (vidi dokumentaciju, poglavlje IAM).
###############################################################################

# Cloud image (Rocky Linux 9) i flavori.
data "openstack_images_image_v2" "os" {
  name        = var.image_name
  most_recent = true
}

# Jedinstveni SSH kljuc za pristup svim instancama.
resource "openstack_compute_keypair_v2" "main" {
  name       = "${var.name_prefix}-key"
  public_key = local.ssh_public_key
}

# Mapa svih Moodle cvorova (2 po programeru) - kljuc "<dev>-01" / "<dev>-02".
locals {
  moodle_nodes = merge([
    for name, idx in local.dev_index : {
      "${name}-01" = { dev = name, node = "01", ip = local.moodle_ips[name].node1 }
      "${name}-02" = { dev = name, node = "02", ip = local.moodle_ips[name].node2 }
    }
  ]...)
}

# ------------------------------- JUMP HOST ---------------------------------
resource "openstack_networking_port_v2" "jump_hub" {
  name               = "${var.name_prefix}-port-jump-hub"
  tenant_id          = local.hub_tenant_id
  network_id         = openstack_networking_network_v2.hub.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.jump.id]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.hub.id
    ip_address = "10.0.0.10"
  }
}

resource "openstack_networking_floatingip_v2" "jump" {
  pool      = var.external_network_name
  tenant_id = local.hub_tenant_id
  tags      = [for k, v in var.common_tags : "${k}=${v}"]
}

resource "openstack_networking_floatingip_associate_v2" "jump" {
  floating_ip = openstack_networking_floatingip_v2.jump.address
  port_id     = openstack_networking_port_v2.jump_hub.id
}

resource "openstack_compute_instance_v2" "jump" {
  name            = "${var.name_prefix}-vm-jump"
  flavor_name     = var.flavor_infra
  key_pair        = openstack_compute_keypair_v2.main.name
  user_data       = file("${path.module}/cloud-init/jump.yaml")
  metadata        = merge(var.common_tags, { role = "jump-host" })
  tags            = [for k, v in var.common_tags : "${k}=${v}"]

  block_device {
    uuid                  = data.openstack_images_image_v2.os.id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = var.os_disk_size_gb
    boot_index            = 0
    delete_on_termination = true
  }

  # Primarni NIC u hub mrezi (nosi floating IP).
  network {
    port = openstack_networking_port_v2.jump_hub.id
  }

  # Dodatni NIC u svakoj dev mrezi (multi-homing -> SSH u sve instance).
  dynamic "network" {
    for_each = openstack_networking_port_v2.jump_in_dev
    content {
      port = network.value.id
    }
  }
}

# ----------------------------- DEVOPS LEAD VM ------------------------------
resource "openstack_networking_port_v2" "lead_hub" {
  name               = "${var.name_prefix}-port-lead-hub"
  tenant_id          = local.hub_tenant_id
  network_id         = openstack_networking_network_v2.hub.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.lead.id]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.hub.id
    ip_address = "10.0.0.11"
  }
}

resource "openstack_compute_instance_v2" "lead" {
  name        = "${var.name_prefix}-vm-lead"
  flavor_name = var.flavor_infra
  key_pair    = openstack_compute_keypair_v2.main.name
  user_data   = file("${path.module}/cloud-init/lead.yaml")
  metadata    = merge(var.common_tags, { role = "devops-lead" })
  tags        = [for k, v in var.common_tags : "${k}=${v}"]

  block_device {
    uuid                  = data.openstack_images_image_v2.os.id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = var.os_disk_size_gb
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    port = openstack_networking_port_v2.lead_hub.id
  }

  dynamic "network" {
    for_each = openstack_networking_port_v2.lead_in_dev
    content {
      port = network.value.id
    }
  }
}

# ------------------------------ MOODLE CVOROVI -----------------------------
# Port po Moodle cvoru s fiksnom adresom i dev security grupom.
resource "openstack_networking_port_v2" "moodle" {
  for_each = local.moodle_nodes

  name               = "${var.name_prefix}-port-moodle-${each.key}"
  tenant_id          = local.dev_tenant_id[each.value.dev]
  network_id         = openstack_networking_network_v2.dev[each.value.dev].id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.app[each.value.dev].id]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.dev[each.value.dev].id
    ip_address = each.value.ip
  }
}

# Aplikacijska instanca: 2 vCPU / 4 GB (flavor_app), OS boot volume + data disk.
resource "openstack_compute_instance_v2" "moodle" {
  for_each = local.moodle_nodes

  name        = "${var.name_prefix}-vm-moodle-${each.value.dev}-${each.value.node}"
  flavor_name = var.flavor_app
  key_pair    = openstack_compute_keypair_v2.main.name
  metadata = merge(var.common_tags, {
    role     = "moodle"
    owner    = each.value.dev
    ha_node  = each.value.node
  })
  tags = [for k, v in var.common_tags : "${k}=${v}"]

  user_data = templatefile("${path.module}/cloud-init/moodle.yaml.tpl", {
    node_index    = each.value.node
    owner         = each.value.dev
    swift_container = "${var.name_prefix}-obj-${each.value.dev}"
    manila_share    = "${var.name_prefix}-file-${each.value.dev}"
  })

  # OS disk (boot-from-volume).
  block_device {
    uuid                  = data.openstack_images_image_v2.os.id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = var.os_disk_size_gb
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    port = openstack_networking_port_v2.moodle[each.key].id
  }
}

# --------------------------- DATA DISK (CINDER) ----------------------------
resource "openstack_blockstorage_volume_v3" "moodle_data" {
  for_each = local.moodle_nodes

  name        = "${var.name_prefix}-vol-data-${each.value.dev}-${each.value.node}"
  size        = var.data_disk_size_gb
  description = "Data disk za Moodle ${each.key} (odvojen od OS diska)."
  metadata    = merge(var.common_tags, { owner = each.value.dev })
}

resource "openstack_compute_volume_attach_v2" "moodle_data" {
  for_each = local.moodle_nodes

  instance_id = openstack_compute_instance_v2.moodle[each.key].id
  volume_id   = openstack_blockstorage_volume_v3.moodle_data[each.key].id
}

###############################################################################
# instances.tf - Moodle VM-ovi (2 po programeru) + DevOps Lead VM
#
# Svaki Moodle VM: 2 vCPU / 4 GB (Standard_B2s), OS Managed disk + 1 data
# Managed disk (ukupno dva Managed diska), bez javnog IP-a, NIC u ASG-u.
###############################################################################

# ----------------------------- MOODLE VM-ovi -------------------------------
resource "azurerm_network_interface" "moodle" {
  for_each = local.moodle_nodes

  name                = "nic-${var.name_prefix}-moodle-${each.value.dev}-${each.value.node}"
  resource_group_name = azurerm_resource_group.dev[each.value.dev].name
  location            = azurerm_resource_group.dev[each.value.dev].location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.app[each.value.dev].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.common_tags, { owner = each.value.dev })
}

# Povezivanje NIC-a s Application Security Grupom.
resource "azurerm_network_interface_application_security_group_association" "moodle" {
  for_each = local.moodle_nodes

  network_interface_id          = azurerm_network_interface.moodle[each.key].id
  application_security_group_id = azurerm_application_security_group.moodle[each.value.dev].id
}

# Povezivanje NIC-a s backend poolom load balancera.
resource "azurerm_network_interface_backend_address_pool_association" "moodle" {
  for_each = local.moodle_nodes

  network_interface_id    = azurerm_network_interface.moodle[each.key].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.moodle[each.value.dev].id
}

resource "azurerm_linux_virtual_machine" "moodle" {
  for_each = local.moodle_nodes

  name                = "vm-${var.name_prefix}-moodle-${each.value.dev}-${each.value.node}"
  resource_group_name = azurerm_resource_group.dev[each.value.dev].name
  location            = azurerm_resource_group.dev[each.value.dev].location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.moodle[each.key].id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  # User-assigned Managed Identity za pristup objektnoj pohrani.
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.moodle[each.value.dev].id]
  }

  os_disk {
    name                 = "disk-${var.name_prefix}-moodle-${each.value.dev}-${each.value.node}-os"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  # Rocky Linux 9 (Marketplace). Zahtijeva prihvacanje plana (vidi plan blok).
  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-base"
    version   = "latest"
  }

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-base"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init/moodle.yaml.tpl", {
    node_index   = each.value.node
    owner        = each.value.dev
    sa_name      = azurerm_storage_account.dev[each.value.dev].name
    file_share   = azurerm_storage_share.backup[each.value.dev].name
    blob_container = azurerm_storage_container.moodle_objects[each.value.dev].name
    identity_client_id = azurerm_user_assigned_identity.moodle[each.value.dev].client_id
  }))

  tags = merge(var.common_tags, {
    owner   = each.value.dev
    role    = "moodle"
    ha_node = each.value.node
  })
}

# --------------------------- DATA MANAGED DISK -----------------------------
resource "azurerm_managed_disk" "moodle_data" {
  for_each = local.moodle_nodes

  name                 = "disk-${var.name_prefix}-moodle-${each.value.dev}-${each.value.node}-data"
  resource_group_name  = azurerm_resource_group.dev[each.value.dev].name
  location             = azurerm_resource_group.dev[each.value.dev].location
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                 = merge(var.common_tags, { owner = each.value.dev })
}

resource "azurerm_virtual_machine_data_disk_attachment" "moodle_data" {
  for_each = local.moodle_nodes

  managed_disk_id    = azurerm_managed_disk.moodle_data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.moodle[each.key].id
  lun                = 0
  caching            = "ReadWrite"
}

# ----------------------------- DEVOPS LEAD VM ------------------------------
resource "azurerm_network_interface" "lead" {
  name                = "nic-${var.name_prefix}-lead"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.common_tags
}

resource "azurerm_linux_virtual_machine" "lead" {
  name                = "vm-${var.name_prefix}-lead"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  size                = var.infra_vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.lead.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  os_disk {
    name                 = "disk-${var.name_prefix}-lead-os"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "resf"
    offer     = "rockylinux-x86_64"
    sku       = "9-base"
    version   = "latest"
  }

  plan {
    publisher = "resf"
    product   = "rockylinux-x86_64"
    name      = "9-base"
  }

  custom_data = base64encode(file("${path.module}/cloud-init/lead.yaml"))

  tags = merge(var.common_tags, { role = "devops-lead" })
}

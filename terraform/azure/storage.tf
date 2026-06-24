###############################################################################
# storage.tf - Storage Account po programeru: Blob (objektna) + Files (datotecna)
#
#  - Blob container: objektna pohrana za Moodle datoteke.
#  - File share (SMB): datotecna pohrana za sigurnosne kopije (backup).
#  - Pristup uz least-privilege: Managed Identity (Blob Data Contributor) za
#    blob, te SAS token / kljuc iz Key Vaulta za SMB montiranje (cloud-init).
#  - Mrezno: dozvoljen pristup samo iz dev subneta (service endpoint).
###############################################################################

resource "random_string" "sa_suffix" {
  for_each = local.developers
  length   = 4
  upper    = false
  special  = false
  numeric  = true
}

resource "azurerm_storage_account" "dev" {
  for_each = local.developers

  name                = substr("${local.sa_name[each.key]}${random_string.sa_suffix[each.key].result}", 0, 24)
  resource_group_name = azurerm_resource_group.dev[each.key].name
  location            = azurerm_resource_group.dev[each.key].location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = true
  public_network_access_enabled   = true

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.app[each.key].id]
    bypass                     = ["AzureServices"]
  }

  tags = merge(var.common_tags, { owner = each.key })
}

# Objektna pohrana (Blob container).
resource "azurerm_storage_container" "moodle_objects" {
  for_each = local.developers

  name                  = "moodle-objects"
  storage_account_id    = azurerm_storage_account.dev[each.key].id
  container_access_type = "private"
}

# Datotecna pohrana (SMB file share) za backupe.
resource "azurerm_storage_share" "backup" {
  for_each = local.developers

  name               = "backup"
  storage_account_id = azurerm_storage_account.dev[each.key].id
  quota              = 50
}

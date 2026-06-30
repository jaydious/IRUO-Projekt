###############################################################################
# identity.tf - User-assigned Managed Identity za Moodle VM-ove + pristup pohrani
#
# Least-privilege: identitet dobiva ulogu "Storage Blob Data Contributor"
# ISKLJUCIVO na vlastitom storage accountu (ne na cijeloj resource grupi).
###############################################################################

resource "azurerm_user_assigned_identity" "moodle" {
  for_each = local.developers

  # Managed identity ime ne smije sadrzavati tocku -> zamijeni "." s "-".
  name                = "id-${var.name_prefix}-moodle-${replace(each.key, ".", "-")}"
  resource_group_name = azurerm_resource_group.dev[each.key].name
  location            = azurerm_resource_group.dev[each.key].location
  tags                = merge(var.common_tags, { owner = each.key })
}

resource "azurerm_role_assignment" "blob_contributor" {
  for_each = local.developers

  scope                = azurerm_storage_account.dev[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.moodle[each.key].principal_id
}

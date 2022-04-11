# We are using AKV to store PGDB password (secret) and need to ensure that the databases in primary and secondary always reference the same password.
resource "azurerm_key_vault" "stamp" {
  for_each            = var.stamps
  name                = "${local.prefix}-${substr(each.value["location"], 0, 5)}-kv"
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  network_acls {
    bypass         = "None"
    default_action = "Allow"
  }
  sku_name = "standard"

  tags = local.default_tags
}

# Give KV secret permissions to the service principal that runs the Terraform apply itself.
resource "azurerm_key_vault_access_policy" "devops_pipeline_all" {
  for_each     = var.stamps
  key_vault_id = azurerm_key_vault.stamp[each.key].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Delete", "Purge", "Set", "Backup", "Restore", "Recover"
  ]
}

# Give the appservices permission to get the secret_permissions
resource "azurerm_key_vault_access_policy" "stamp_appservice" {
  for_each     = var.stamps
  key_vault_id = azurerm_key_vault.stamp[each.key].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.appservice[each.key].identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]
}
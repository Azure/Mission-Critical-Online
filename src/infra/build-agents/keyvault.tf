resource "azurerm_key_vault" "deployment" {
  name                        = "${local.prefix}-kv"
  location                    = azurerm_resource_group.deployment.location
  resource_group_name         = azurerm_resource_group.deployment.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  tags = local.default_tags
}

resource "azurerm_key_vault_access_policy" "devops_pipeline" {
  key_vault_id = azurerm_key_vault.deployment.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Delete", "Purge", "Set", "Backup", "Restore", "Recover"
  ]
}

resource "random_password" "vmsecret" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# Password for SSH logon to the build agents as well as jump servers
resource "azurerm_key_vault_secret" "vmsecret" {
  depends_on   = [azurerm_key_vault_access_policy.devops_pipeline]
  name         = "vmadmin-secret"
  value        = random_password.vmsecret.result
  key_vault_id = azurerm_key_vault.deployment.id
}
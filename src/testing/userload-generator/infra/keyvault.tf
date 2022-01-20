resource "azurerm_key_vault" "deployment" {
  name                        = "${local.prefix}-loadgen-kv"
  location                    = azurerm_resource_group.deployment.location
  resource_group_name         = azurerm_resource_group.deployment.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  tags = local.default_tags
}

# Give KV secret permissions to the service principal that runs the Terraform apply itself
resource "azurerm_key_vault_access_policy" "devops_pipeline" {
  key_vault_id = azurerm_key_vault.deployment.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "get", "list", "delete", "purge", "set", "backup", "restore", "recover"
  ]
}

resource "azurerm_key_vault_access_policy" "function_msi" {
  key_vault_id = azurerm_key_vault.deployment.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_user_assigned_identity.functions.principal_id

  secret_permissions = [
    "get", "list"
  ]
}

# Set each Function host key as a KV secret named "FUNCTIONKEY-MY-FUNCTION-NAME"
resource "azurerm_key_vault_secret" "functionkeys" {
  depends_on = [
    azurerm_key_vault_access_policy.devops_pipeline
  ]

  for_each = module.regional_functions

  name         = "FUNCTIONKEY-${upper(each.value.function_name)}"
  value        = each.value.function_host_key
  key_vault_id = azurerm_key_vault.deployment.id
}
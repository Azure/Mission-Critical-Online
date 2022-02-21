resource "azurerm_key_vault" "deployment" {
  name                       = "${local.prefix}-loadtest-kv"
  location                   = azurerm_resource_group.deployment.location
  resource_group_name        = azurerm_resource_group.deployment.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  sku_name = "standard"
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

resource "random_password" "locustsecret" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "locustsecret" {
  depends_on = [
    azurerm_key_vault_access_policy.devops_pipeline
  ]

  name         = "locust-webauth-secret"
  value        = random_password.locustsecret.result
  key_vault_id = azurerm_key_vault.deployment.id
}
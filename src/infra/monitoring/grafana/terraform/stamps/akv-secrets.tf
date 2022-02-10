# Create a random password for PGDB. This password is then stored in Azure Key Vault.
resource "random_password" "postgres_password" {
  length           = 10
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  special          = true
  override_special = "_%@"
}

# Random password used to log into the Grafana portal
resource "random_password" "grafana_password" {
  length           = 10
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "postgres_password" {
  for_each     = var.stamps
  name         = "pgdb-admin-pwd"
  value        = random_password.postgres_password.result
  key_vault_id = azurerm_key_vault.stamp[each.key].id
  depends_on   = [azurerm_key_vault_access_policy.devops_pipeline_all]
}

resource "azurerm_key_vault_secret" "grafana_password" {
  for_each     = var.stamps
  name         = "grafana-pwd"
  value        = random_password.grafana_password.result
  key_vault_id = azurerm_key_vault.stamp[each.key].id
  depends_on   = [azurerm_key_vault_access_policy.devops_pipeline_all]
}
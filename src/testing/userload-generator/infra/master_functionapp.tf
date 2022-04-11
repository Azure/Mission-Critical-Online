resource "azurerm_service_plan" "master" {
  name                = "${local.prefix}-loadgen-master-func-asp"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = local.default_tags
}

resource "azurerm_linux_function_app" "master" {
  name                        = "${local.prefix}-loadgen-master-func"
  location                    = azurerm_resource_group.deployment.location
  resource_group_name         = azurerm_resource_group.deployment.name
  service_plan_id             = azurerm_service_plan.master.id
  storage_account_name        = azurerm_storage_account.master.name
  storage_account_access_key  = azurerm_storage_account.master.primary_access_key
  functions_extension_version = "~4"
  https_only                  = true

  tags = local.default_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.functions.id]
  }

  site_config {}

  key_vault_reference_identity_id = azurerm_user_assigned_identity.functions.id

  app_settings = merge(
    local.function_names_per_geo,
    { for secret in azurerm_key_vault_secret.functionkeys : replace(upper(secret.name), "-", "_") => "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.deployment.name};SecretName=${secret.name})" },
    {
      "FUNCTIONS_WORKER_RUNTIME"              = "dotnet",
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.deployment.connection_string
      "WEBSITE_MOUNT_ENABLED"                 = "1"
      "WEBSITE_RUN_FROM_PACKAGE"              = "" # This value will be set by the Function deployment later
    }
  )
}
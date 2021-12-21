resource "azurerm_app_service_plan" "regional" {
  name                = "${var.prefix}-loadgen-${var.location}-func-asp"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  tags = var.default_tags
}

resource "azurerm_function_app" "regional" {
  name                       = "${var.prefix}-loadgen-${var.location}-func"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_app_service_plan.regional.id
  storage_account_name       = azurerm_storage_account.regional.name
  storage_account_access_key = azurerm_storage_account.regional.primary_access_key
  os_type                    = "linux"
  version                    = "~4"

  tags = var.default_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.function_user_managed_identity_resource_id]
  }

  key_vault_reference_identity_id = var.function_user_managed_identity_resource_id

  site_config {
    linux_fx_version = "NODE|14"
  }

  app_settings = merge(
    var.additional_app_settings,
    {
      "FUNCTIONS_WORKER_RUNTIME"       = "node"
      "PLAYWRIGHT_BROWSERS_PATH"       = "0"
      "ENABLE_ORYX_BUILD"              = "true"
      "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
      "WEBSITE_MOUNT_ENABLED"          = "1"
      "WEBSITE_RUN_FROM_PACKAGE"       = "" # This value will be set by the Function deployment later
  })
}

data "azurerm_function_app_host_keys" "regional" {
  name                = azurerm_function_app.regional.name
  resource_group_name = var.resource_group_name
}
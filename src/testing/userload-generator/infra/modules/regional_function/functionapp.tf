resource "azurerm_service_plan" "regional" {
  name                = "${var.prefix}-loadgen-${var.location}-func-asp"
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type  = "Linux"
  sku_name = "Y1"

  tags = var.default_tags
}

resource "azurerm_linux_function_app" "regional" {
  name                        = "${var.prefix}-loadgen-${var.location}-func"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  service_plan_id             = azurerm_service_plan.regional.id
  storage_account_name        = azurerm_storage_account.regional.name
  storage_account_access_key  = azurerm_storage_account.regional.primary_access_key
  functions_extension_version = "~4"
  https_only                  = true

  tags = var.default_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.function_user_managed_identity_resource_id]
  }

  key_vault_reference_identity_id = var.function_user_managed_identity_resource_id

  site_config {
    application_stack {
      node_version = "14"
    }

    application_insights_connection_string = var.application_insights_connection_string
  }

  app_settings = merge(
    var.additional_app_settings,
    {
      "PLAYWRIGHT_BROWSERS_PATH"       = "0"
      "ENABLE_ORYX_BUILD"              = "true"
      "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
      "WEBSITE_MOUNT_ENABLED"          = "1"
      "WEBSITE_RUN_FROM_PACKAGE"       = "" # This value will be set by the Function deployment later
  })

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"], # prevent TF reporting configuration drift after app code is deployed
    ]
  }
}

data "azurerm_function_app_host_keys" "regional" {
  name                = azurerm_linux_function_app.regional.name
  resource_group_name = var.resource_group_name
}
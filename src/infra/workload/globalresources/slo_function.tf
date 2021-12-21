# This template contains the Azure Function that is used to run the SLO calculation on a timer trigger

# This storage account is being used for the SLO process Function hosting
resource "azurerm_storage_account" "monitoring" {
  name                     = "${local.prefix}slofuncstg"
  resource_group_name      = azurerm_resource_group.monitoring.name
  location                 = azurerm_resource_group.monitoring.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  min_tls_version          = "TLS1_2"

  tags = local.default_tags
}

resource "azurerm_user_assigned_identity" "slo_function" {
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location

  name = "${local.prefix}-slo-function-identity"

  tags = local.default_tags
}

resource "azurerm_app_service_plan" "monitoring" {
  name                = "${local.prefix}-slo-func-asp"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  tags = local.default_tags
}

resource "azurerm_function_app" "slo_query" {
  name                       = "${local.prefix}-slo-func"
  location                   = azurerm_resource_group.monitoring.location
  resource_group_name        = azurerm_resource_group.monitoring.name
  app_service_plan_id        = azurerm_app_service_plan.monitoring.id
  storage_account_name       = azurerm_storage_account.monitoring.name
  storage_account_access_key = azurerm_storage_account.monitoring.primary_access_key
  os_type                    = "linux"
  version                    = "~4"
  https_only                 = true

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.monitoring.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME       = "dotnet"
    LA_WORKSPACE_SHARED_KEY_GLOBAL = azurerm_log_analytics_workspace.global.primary_shared_key
    LA_WORKSPACE_ID_GLOBAL         = azurerm_log_analytics_workspace.global.workspace_id
    LA_WORKSPACE_IDS_STAMPS        = join("|", [for stamp in module.stamp_monitoring : stamp.log_analytics_workspace_id])
    USER_ASSIGNED_CLIENT_ID        = azurerm_user_assigned_identity.slo_function.client_id
    WEBSITE_MOUNT_ENABLED          = "1"
    WEBSITE_RUN_FROM_PACKAGE       = "" # This value will be set by the Function deployment later
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.slo_function.id]
  }

  tags = local.default_tags
}


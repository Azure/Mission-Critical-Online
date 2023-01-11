# Data sources used for configuring LA workspace
data "azurerm_monitor_diagnostic_categories" "frontdoor" {
  resource_id = azurerm_frontdoor.afdgrafana.id
}

data "azurerm_monitor_diagnostic_categories" "acr" {
  resource_id = azurerm_container_registry.main.id
}

data "azuread_group" "grafana_access" {
  object_id = var.auth_group_id # import aad group that grants access to grafana
}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_client_config" "current" {}
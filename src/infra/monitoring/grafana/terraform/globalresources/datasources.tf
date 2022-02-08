# Data sources used for configuring LA workspace
data "azurerm_monitor_diagnostic_categories" "frontdoor" {
  resource_id = azurerm_frontdoor.afdgrafana.id
}

data "azurerm_monitor_diagnostic_categories" "acr" {
  resource_id = azurerm_container_registry.main.id
}
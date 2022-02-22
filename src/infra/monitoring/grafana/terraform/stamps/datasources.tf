# Referenced in akv.tf.The values are used to grant privileges to the principal executing Terraform templates.
data "azurerm_client_config" "current" {}

# The following data sources are used for configuring LA workspace for individual services. 
data "azurerm_monitor_diagnostic_categories" "asp" {
  for_each    = var.stamps
  resource_id = azurerm_app_service_plan.asp[each.key].id
}

data "azurerm_monitor_diagnostic_categories" "appservice" {
  for_each    = var.stamps
  resource_id = azurerm_app_service.appservice[each.key].id
}

data "azurerm_monitor_diagnostic_categories" "pgprimary" {
  resource_id = azurerm_postgresql_server.pgprimary.id
}

data "azurerm_monitor_diagnostic_categories" "pgreplica" {
  resource_id = azurerm_postgresql_server.pgreplica.id
}

data "azurerm_monitor_diagnostic_categories" "vnet" {
  for_each    = var.stamps
  resource_id = azurerm_virtual_network.vnet[each.key].id
}

data "azurerm_monitor_diagnostic_categories" "akv" {
  for_each    = var.stamps
  resource_id = azurerm_key_vault.stamp[each.key].id
}

data "azurerm_subscription" "current" {
}
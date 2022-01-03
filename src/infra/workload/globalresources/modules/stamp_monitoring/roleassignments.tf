resource "azurerm_role_assignment" "stamp" {
  scope                = azurerm_log_analytics_workspace.stamp.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = var.azure_monitor_function_principal_id
}
output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.stamp.workspace_id
}

output "azure_monitor_workspace_id" {
  value = azurerm_monitor_workspace.stamp.id
}

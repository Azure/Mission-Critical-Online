output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.stamp.workspace_id
}

output "appinsights_instrumentation_key" {
  value = azurerm_application_insights.stamp.instrumentation_key
}

output "location" {
  value = var.location
}
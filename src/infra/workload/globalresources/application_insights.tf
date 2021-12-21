# Application insights which is used by the SLO query Function
resource "azurerm_application_insights" "monitoring" {
  name                 = "${local.prefix}-global-appi"
  location             = azurerm_resource_group.monitoring.location
  resource_group_name  = azurerm_resource_group.monitoring.name
  application_type     = "web"
  daily_data_cap_in_gb = 30

  workspace_id = azurerm_log_analytics_workspace.global.id

  tags = local.default_tags
}
resource "azurerm_log_analytics_workspace" "deployment" {
  name                = "${local.prefix}-loadgen-log"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # has to be between 30 and 730
  daily_quota_gb      = var.law_daily_cap_gb

  tags = local.default_tags
}

resource "azurerm_application_insights" "deployment" {
  name                 = "${local.prefix}-loadgen-appi"
  location             = azurerm_resource_group.deployment.location
  resource_group_name  = azurerm_resource_group.deployment.name
  application_type     = "web"
  workspace_id         = azurerm_log_analytics_workspace.deployment.id
  daily_data_cap_in_gb = var.law_daily_cap_gb

  tags = local.default_tags
}

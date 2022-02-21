resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "${local.prefix}-global-log"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # has to be between 30 and 730

  daily_quota_gb = 10

  tags = local.default_tags
}
resource "azurerm_application_insights" "deployment" {
  name                 = "${local.prefix}-loadgen-appi"
  location             = azurerm_resource_group.deployment.location
  resource_group_name  = azurerm_resource_group.deployment.name
  application_type     = "web"
  daily_data_cap_in_gb = 30

  tags = local.default_tags
}

# Adding a LogAnalytics Workspace for the globally shared resources
resource "azurerm_log_analytics_workspace" "global" {
  name                = "${local.prefix}-global-log"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # has to be between 30 and 730

  daily_quota_gb = var.law_daily_cap_gb

  tags = local.default_tags
}

# Imports all *.kql files from src/infra/monitoring/queries/global/ (local.kql_queries)
resource "azurerm_log_analytics_saved_search" "queries" {
  for_each = fileset("${local.kql_queries}/", "*.kql")

  name           = split(".", each.value)[0] # each.value is the full file name including the extension (MyFile.kql). So we split it and use only the name without extension
  display_name   = split(".", each.value)[0]
  category       = "HealthModel"
  query          = file("${local.kql_queries}/${each.value}")
  function_alias = split(".", each.value)[0]

  log_analytics_workspace_id = azurerm_log_analytics_workspace.global.id
}
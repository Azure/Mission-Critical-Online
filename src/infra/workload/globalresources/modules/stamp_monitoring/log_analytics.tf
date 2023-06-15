# Adding a LogAnalytics Workspace for AKS and Container Insights
resource "azurerm_log_analytics_workspace" "stamp" {
  name                = "${local.prefix}-${local.location_short}-log"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # has to be between 30 and 730
  daily_quota_gb      = var.law_daily_cap_gb

  tags = var.default_tags
}

# ############
# Log Analytics stored functions used for Health Modeling
# ############

# Imports all *.kql files from src/infra/monitoring/queries/ (local.kql_queries)
resource "azurerm_log_analytics_saved_search" "queries" {
  for_each = fileset("${local.kql_queries}/", "*.kql")

  name           = split(".", each.value)[0] # each.value is the full file name including the extension (MyFile.kql). So we split it and use only the name without extension
  display_name   = split(".", each.value)[0]
  category       = "HealthModel"
  query          = file("${local.kql_queries}/${each.value}")
  function_alias = split(".", each.value)[0]

  log_analytics_workspace_id = azurerm_log_analytics_workspace.stamp.id
}


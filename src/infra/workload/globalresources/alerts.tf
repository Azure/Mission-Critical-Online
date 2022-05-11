resource "azurerm_monitor_action_group" "main" {
  name                = "${local.prefix}-alwayson-default-actiongroup"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "AO Def AG"

  email_receiver {
    name          = "SendToOpsTeam"
    email_address = var.contact_email
  }
}

# Metric alert on Front Door BackendHealth
# Will fire when any backend health drops below 80 percent in the last minute
resource "azurerm_monitor_metric_alert" "frontdoor_backend_health" {
  name                = "FrontDoor-metricalert-backendHealth"
  resource_group_name = azurerm_resource_group.monitoring.name
  scopes              = [azurerm_frontdoor.main.id]
  description         = "Action will be triggered when Backend Health for a certain Backend drops under 80 percent."

  window_size = "PT1M" # average over the last minute
  frequency   = "PT1M" # check every minute

  severity = 1 # 1: Error

  enabled = var.alerts_enabled

  criteria {
    metric_namespace = "Microsoft.Network/frontdoors"
    metric_name      = "BackendHealthPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 80

    dimension {
      name     = "Backend"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
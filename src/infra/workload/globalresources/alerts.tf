resource "azurerm_monitor_action_group" "main" {
  name                = "${local.prefix}-alwayson-default-actiongroup"
  resource_group_name = azurerm_resource_group.monitoring.name
  short_name          = "AO Def AG"

  email_receiver {
    name          = "SendToOpsTeam"
    email_address = var.contact_email
  }
}

# Metric alert on Front Door OriginHealth
# Will fire when any origin health drops below 80 per cent in the last minute
resource "azurerm_monitor_metric_alert" "frontdoor_origin_health" {
  name                = "FrontDoor-metricalert-originHealth"
  resource_group_name = azurerm_resource_group.monitoring.name
  scopes              = [azurerm_cdn_frontdoor_profile.main.id]
  description         = "Action will be triggered when Origin Health for a certain Origin drops under 80 per cent."

  window_size = "PT1M" # average over the last minute
  frequency   = "PT1M" # check every minute

  severity = 1 # 1: Error

  enabled = var.alerts_enabled

  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "OriginHealthPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 80

    dimension {
      name     = "Origin"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
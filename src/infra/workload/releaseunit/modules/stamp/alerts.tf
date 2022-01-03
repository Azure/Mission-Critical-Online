# Warning Metric alert on the count of Event Hub outgoing messages
# Will be triggered when the number of outgoing messages drops under threshold. 
# This often indicates some issue on the sending side (HealthService or CatalogService)
resource "azurerm_monitor_metric_alert" "eh_outgoging_messages_warning" {
  name                = "EventHub-metricalert-OutgoingMessages-Warning"
  resource_group_name = azurerm_resource_group.stamp.name
  scopes              = [azurerm_eventhub_namespace.stamp.id]
  description         = "Action will be triggered when the number of outgoing messages drops under threshold. This often indicates some issue on the sending side (HealthService or CatalogService)."

  window_size = "PT1M" # average over the last minute
  frequency   = "PT1M" # check every minute

  severity = 2 # 2: Warning

  enabled = var.alerts_enabled

  criteria {
    metric_namespace = "Microsoft.EventHub/namespaces"
    metric_name      = "OutgoingMessages"
    aggregation      = "Total"
    operator         = "LessThan"
    threshold        = 5 # We expect a certain baseline load, just from the health check. Once it drops below this baseline (but not yet to zero), we want to be notified

    dimension {
      name     = "EntityName"
      operator = "Include"
      values   = [azurerm_eventhub.backendqueue.name]
    }
  }

  action {
    action_group_id = var.azure_monitor_action_group_resource_id
  }
}


# Warning Metric alert on Event Hub outgoing messages counts
# Will be triggered when number of outgoing messages drops to zero. 
# This often indicates some issue on the receiving end (BackgroundProcessor)
resource "azurerm_monitor_metric_alert" "eh_outgoging_messages_error" {
  name                = "EventHub-metricalert-OutgoingMessages-Error"
  resource_group_name = azurerm_resource_group.stamp.name
  scopes              = [azurerm_eventhub_namespace.stamp.id]
  description         = "Action will be triggered when number of outgoing messages drops to zero. This often indicates some issue on the receiving end (BackgroundProcessor)."

  window_size = "PT1M" # average over the last minute
  frequency   = "PT1M" # check every minute

  severity = 0 # 0: Critical

  enabled = var.alerts_enabled

  criteria {
    metric_namespace = "Microsoft.EventHub/namespaces"
    metric_name      = "OutgoingMessages"
    aggregation      = "Total"
    operator         = "LessThanOrEqual"
    threshold        = 0

    dimension {
      name     = "EntityName"
      operator = "Include"
      values   = [azurerm_eventhub.backendqueue.name]
    }
  }

  action {
    action_group_id = var.azure_monitor_action_group_resource_id
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert" "game_service_exception_responses" {
  name                = "${local.prefix}-${local.location_short}-AppInsights-CatalogServiceExceptionReponses"
  location            = var.location
  resource_group_name = var.resource_group_name

  data_source_id = azurerm_application_insights.stamp.id
  description    = "Alert will be triggered when CatalogService exception response threshold reached. Every 5xx response to a request counts as an exception"

  enabled = var.alerts_enabled

  # Count all requests with server error result code grouped into 5-minute bins
  query       = <<-QUERY
  requests
  | where cloud_RoleName startswith "CatalogService" and name !contains "Health" and resultCode startswith "5"
  QUERY
  severity    = 1
  frequency   = 5
  time_window = 5

  trigger {
    operator  = "GreaterThan"
    threshold = 10
  }

  action {
    action_group = [
      var.azure_monitor_action_group_resource_id
    ]
  }
}
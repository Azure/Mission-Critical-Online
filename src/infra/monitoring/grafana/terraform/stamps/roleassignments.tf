# Permission for App Services to pull images from the globally shared ACR
resource "azurerm_role_assignment" "acrpull_role" {
  for_each             = local.stamps
  scope                = var.acr_resource_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.appservice[each.key].identity[0].principal_id
}

# Permission for Grafana to read from all Log Analytics workspaces in the subscription
resource "azurerm_role_assignment" "loganalyticsreader_role" {
  for_each             = local.stamps
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_linux_web_app.appservice[each.key].identity[0].principal_id
}
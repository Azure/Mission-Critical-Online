resource "azurerm_user_assigned_identity" "functions" {
  resource_group_name = azurerm_resource_group.deployment.name
  location            = azurerm_resource_group.deployment.location

  name = "${local.prefix}-loadgen-functions-identity"

  tags = local.default_tags
}
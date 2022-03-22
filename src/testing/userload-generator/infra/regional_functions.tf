module "regional_functions" {
  for_each = local.regions # Get all regions. They must be unique
  source   = "./modules/regional_function"

  location            = each.key
  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.deployment.name
  additional_app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.deployment.connection_string
    "TEST_BASEURL"                          = var.targeturl
  }

  function_user_managed_identity_resource_id = azurerm_user_assigned_identity.functions.id

  default_tags = local.default_tags
}
# For each stamp we are deploying the long-living monitoring resources.
# This is so that they will not be tied to the lifecycle of individual releases/stamps
# and we don't lose operational data when a new release gets deployed.
# - Log Analytics Workspace
# - Saved queries for the health model
# - Application Insights

module "stamp_monitoring" {
  for_each = toset(var.stamps) # for each needs a set, cannot work with a list
  source   = "./modules/stamp_monitoring"

  location                               = each.value
  prefix                                 = local.prefix
  resource_group_name                    = azurerm_resource_group.monitoring.name
  azure_monitor_action_group_resource_id = azurerm_monitor_action_group.main.id
  alerts_enabled                         = var.alerts_enabled
  default_tags                           = local.default_tags
}
locals {
  # regions where the creation of azure monitor workspaces is currently not supported - with a fallback region provided
  region_fallbacks = {
    "australiaeast" = "australiasoutheast"
  }
}

resource "azurerm_monitor_workspace" "stamp" {
  name                = "${local.prefix}-${local.location_short}-amw"
  resource_group_name = var.resource_group_name
  location            = lookup(local.region_fallbacks, var.location, var.location) # If the region is set in the region_fallbacks maps, we use the fallback, otherwise the region as chosen by the user

}
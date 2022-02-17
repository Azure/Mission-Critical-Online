resource "azurerm_container_registry" "main" {
  name                = "${local.prefix}globalcr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = false

  zone_redundancy_enabled = false # Disabled for now as it is still in preview and not supported in all regions. Can be enabled if you know that all the stamp's regions support it already.

  dynamic "georeplications" {
    for_each = [for location in var.stamps : location if azurerm_resource_group.rg.location != location] # remove the location of the ACR iteself from the list of replicas
    content {
      location = georeplications.value

      zone_redundancy_enabled = false # Disabled for now as it is still in preview and not supported in all regions. Can be enabled if you know that all the stamp's regions support it already.
    }
  }

  tags = local.default_tags
}
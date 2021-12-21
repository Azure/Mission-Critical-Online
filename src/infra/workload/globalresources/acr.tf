resource "azurerm_container_registry" "main" {
  name                = "${local.prefix}globalcr"
  resource_group_name = azurerm_resource_group.global.name
  location            = azurerm_resource_group.global.location
  sku                 = "Premium"
  admin_enabled       = false

  public_network_access_enabled = !var.private_mode # If using private_mode, we limit access to private endpoints, otherwise allow all so that the build agent can access

  zone_redundancy_enabled = false # Disabled for now as it is still in preview and not supported in all regions. Can be enabled if you know that all the stamp's regions support it already.

  dynamic "georeplications" {
    for_each = [for location in var.stamps : location if azurerm_resource_group.global.location != location] # remove the location of the ACR iteself from the list of replicas
    content {
      location = georeplications.value

      zone_redundancy_enabled = false # Disabled for now as it is still in preview and not supported in all regions. Can be enabled if you know that all the stamp's regions support it already.
    }
  }

  tags = local.default_tags
}

####################################### DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "acr" {
  resource_id = azurerm_container_registry.main.id
}

resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                       = "acrladiagnostics"
  target_resource_id         = azurerm_container_registry.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.global.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.acr.logs

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  dynamic "metric" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.acr.metrics

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }
}

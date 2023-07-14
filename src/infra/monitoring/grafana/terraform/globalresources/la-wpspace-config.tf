# Azure Frontdoor config for LA workspace

resource "azurerm_monitor_diagnostic_setting" "diag_settings_afd" {
  name                       = "frontdoorladiagnostics"
  target_resource_id         = azurerm_frontdoor.afdgrafana.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  dynamic "enabled_log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.frontdoor.log_category_types

    content {
      category = entry.value

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  dynamic "metric" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.frontdoor.metrics

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


# Azure Container Registry

resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                       = "acrladiagnostics"
  target_resource_id         = azurerm_container_registry.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  dynamic "enabled_log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.acr.log_category_types

    content {
      category = entry.value

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

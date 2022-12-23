resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "${local.prefix}-global-log"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # has to be between 30 and 730

  daily_quota_gb = 10

  tags = local.default_tags
}

# Azure Frontdoor config for LA workspace
resource "azurerm_monitor_diagnostic_setting" "diag_settings_afd" {
  name                       = "frontdoorladiagnostics"
  target_resource_id         = azurerm_frontdoor.afdgrafana.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.frontdoor.log_category_types

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

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.acr.log_category_types

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

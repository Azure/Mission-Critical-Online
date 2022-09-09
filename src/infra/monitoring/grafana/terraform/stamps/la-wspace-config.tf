# This template enables capture for diagnostic settings and metrics, and writes them to the LA Workspace deployed as part of global resources.

# App service instances 
resource "azurerm_monitor_diagnostic_setting" "appservice" {
  for_each                   = local.stamps
  name                       = "${local.prefix}-${substr(each.value, 0, 5)}-appdiag"
  target_resource_id         = azurerm_linux_web_app.appservice[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace[each.key].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.appservice[each.key].log_category_types

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
    for_each = data.azurerm_monitor_diagnostic_categories.appservice[each.key].metrics

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

# PostgreSQL databases

resource "azurerm_monitor_diagnostic_setting" "pgprimary" {
  name                       = "pgdbdiagnostics-primary"
  target_resource_id         = azurerm_postgresql_server.pgprimary.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace[0].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.pgprimary.log_category_types

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
    for_each = data.azurerm_monitor_diagnostic_categories.pgprimary.metrics

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


resource "azurerm_monitor_diagnostic_setting" "pgreplica" {
  for_each                   = azurerm_postgresql_server.pgreplica
  name                       = "pgdbdiagnostics-replicas"
  target_resource_id         = azurerm_postgresql_server.pgreplica[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace[each.key].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.pgreplica[each.key].log_category_types

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
    for_each = data.azurerm_monitor_diagnostic_categories.pgreplica[each.key].metrics

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

# Virtual Networks

resource "azurerm_monitor_diagnostic_setting" "vnet" {
  for_each                   = local.stamps
  name                       = "${local.prefix}-${substr(each.value, 0, 5)}-vnetdiag"
  target_resource_id         = azurerm_virtual_network.vnet[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace[each.key].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.vnet[each.key].log_category_types

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
    for_each = data.azurerm_monitor_diagnostic_categories.vnet[each.key].metrics

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

# App Service Plan (ASP)

resource "azurerm_monitor_diagnostic_setting" "asp" {
  for_each                   = local.stamps
  name                       = "${local.prefix}-${substr(each.value, 0, 5)}-aspdiag"
  target_resource_id         = azurerm_service_plan.asp[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace[each.key].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.asp[each.key].log_category_types

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
    for_each = data.azurerm_monitor_diagnostic_categories.asp[each.key].metrics

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

# Azure Key Vault

resource "azurerm_monitor_diagnostic_setting" "akv" {
  for_each                   = local.stamps
  name                       = "${local.prefix}-${substr(each.value, 0, 5)}-akvdiag"
  target_resource_id         = azurerm_key_vault.stamp[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace[each.key].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.akv[each.key].log_category_types

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
    for_each = data.azurerm_monitor_diagnostic_categories.akv[each.key].metrics

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

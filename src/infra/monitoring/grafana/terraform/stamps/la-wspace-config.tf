# This template enables capture for diagnostic settings and metrics, and writes them to the LA Workspace deployed as part of global resources.

# App service instances 
resource "azurerm_monitor_diagnostic_setting" "appservice" {
  for_each                   = var.stamps
  name                       = "${local.prefix}-${substr(each.value["location"], 0, 5)}-appdiag"
  target_resource_id         = azurerm_app_service.appservice[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace[each.key].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.appservice[each.key].logs

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
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace["primary"].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.pgprimary.logs

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
  name                       = "pgdbdiagnostics-replica"
  target_resource_id         = azurerm_postgresql_server.pgreplica.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace["secondary"].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.pgreplica.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.pgreplica.metrics

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
  for_each                   = var.stamps
  name                       = "${local.prefix}-${substr(each.value["location"], 0, 5)}-vnetdiag"
  target_resource_id         = azurerm_virtual_network.vnet[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace[each.key].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.vnet[each.key].logs

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
  for_each                   = var.stamps
  name                       = "${local.prefix}-${substr(each.value["location"], 0, 5)}-aspdiag"
  target_resource_id         = azurerm_app_service_plan.asp[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace[each.key].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.asp[each.key].logs

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
  for_each                   = var.stamps
  name                       = "${local.prefix}-${substr(each.value["location"], 0, 5)}-akvdiag"
  target_resource_id         = azurerm_key_vault.stamp[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace[each.key].id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.akv[each.key].logs

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

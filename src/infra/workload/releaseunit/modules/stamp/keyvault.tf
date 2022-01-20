resource "azurerm_key_vault" "stamp" {
  name                = "${local.prefix}-${local.location_short}-kv"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  tags = var.default_tags
}

# Give KV secret permissions to the service principal that runs the Terraform apply itself
resource "azurerm_key_vault_access_policy" "devops_pipeline_all" {
  key_vault_id = azurerm_key_vault.stamp.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Delete", "Purge", "Set", "Backup", "Restore", "Recover"
  ]
}

# Give KV secret read permissions to the Managed Identity of AKS for CSI driver access
resource "azurerm_key_vault_access_policy" "aks_msi" {
  key_vault_id = azurerm_key_vault.stamp.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_kubernetes_cluster.stamp.kubelet_identity.0.object_id

  secret_permissions = [
    "Get", "List"
  ]
}

####################################### DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "kv" {
  resource_id = azurerm_key_vault.stamp.id
}

resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "kvladiagnostics"
  target_resource_id         = azurerm_key_vault.stamp.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.stamp.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.kv.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.kv.metrics

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

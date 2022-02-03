# https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html
resource "azurerm_kubernetes_cluster" "stamp" {
  name                = "${local.prefix}-${local.location_short}-aks"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  dns_prefix          = "${local.prefix}${var.location}aks"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "MC_${local.prefix}-stamp-${var.location}-aks-rg" # we manually specify the naming of the managed resource group to have it controlled and consistent
  sku_tier            = "Paid"                                          # Opt-in for AKS Uptime SLA

  automatic_channel_upgrade = "node-image"

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2]
    }
  }

  role_based_access_control {
    enabled = true
  }

  default_node_pool {
    name                 = "defaultpool"
    vm_size              = var.aks_node_size
    enable_auto_scaling  = true
    min_count            = var.aks_node_pool_autoscale_minimum
    max_count            = var.aks_node_pool_autoscale_maximum
    vnet_subnet_id       = azurerm_subnet.kubernetes.id
    os_disk_type         = "Ephemeral"
    orchestrator_version = var.kubernetes_version
    availability_zones   = [1, 2, 3]

    upgrade_settings {
      max_surge = "33%"
    }

    tags = var.default_tags
  }

  network_profile {
    network_plugin = "azure"
    network_mode   = "transparent"
    network_policy = "azure"
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = data.azurerm_log_analytics_workspace.stamp.id
    }

    azure_policy {
      enabled = true
    }

    kube_dashboard {
      enabled = false
    }

    azure_keyvault_secrets_provider {
      enabled                  = true
      secret_rotation_enabled  = true
      secret_rotation_interval = "5m"
    }
  }

  depends_on = [
    azurerm_public_ip.aks_ingress
  ]

  tags = var.default_tags
}

####################################### DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "aks" {
  resource_id = azurerm_kubernetes_cluster.stamp.id
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "aksladiagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.stamp.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.stamp.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.aks.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.aks.metrics

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

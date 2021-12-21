# This "public" storage account is being used for the static website hosting
resource "azurerm_storage_account" "public" {
  name                     = "${local.prefix}${local.location_short}pubst"
  resource_group_name      = azurerm_resource_group.stamp.name
  location                 = azurerm_resource_group.stamp.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  min_tls_version          = "TLS1_2"

  # Enable static website hosting. We will use that to host our UI app
  static_website {
    index_document = "index.html"
  }

  tags = var.default_tags
}

# This "private" storage account is being used for stamp-internal matters such as the health service blob storage
resource "azurerm_storage_account" "private" {
  name                     = "${local.prefix}${local.location_short}prist"
  resource_group_name      = azurerm_resource_group.stamp.name
  location                 = azurerm_resource_group.stamp.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  min_tls_version          = "TLS1_2"

  network_rules {
    default_action = var.private_mode ? "Deny" : "Allow" # If private_mode == true, then deny all access - except for the private endpoint connections
    bypass         = ["Metrics", "Logging"]
    ip_rules       = []
  }

  tags = var.default_tags
}

# We need to wait a while for the newly created Private Endpoints to Storage for the Build agent to become active before attempting to write containers or files into storage
# If not running in private mode (var.private_mode == true), this timer is not being used
resource "time_sleep" "wait_storage" {
  count      = var.private_mode ? 1 : 0 # only relevant if we deploy a private stamp
  depends_on = [azurerm_private_endpoint.buildagent_storage_blob, azurerm_private_endpoint.buildagent_storage_table]

  create_duration = "300s" # 5min should give us enough time. The entire deployment anyway takes much longer because of the CosmosDB private endpoint
}

# Storage container for the checkpoints of the Event Hub processors
resource "azurerm_storage_container" "deployment_eventhub_checkpoints" {
  depends_on            = [time_sleep.wait_storage]
  name                  = "ehcheckpoints"
  storage_account_name  = azurerm_storage_account.private.name
  container_access_type = "private"
}

# Storage container for the healthservice
resource "azurerm_storage_container" "deployment_healthservice" {
  depends_on            = [time_sleep.wait_storage]
  name                  = "healthservice"
  storage_account_name  = azurerm_storage_account.private.name
  container_access_type = "private"
}

# Create empty file which serves as the healthservice state file
resource "azurerm_storage_blob" "healthservice_state_blob" {
  name                   = local.health_blob_name
  storage_account_name   = azurerm_storage_account.private.name
  storage_container_name = azurerm_storage_container.deployment_healthservice.name
  type                   = "Block"
  source_content         = ""
}

# Poison Messages Table for the ResultWorker to store errored messages
resource "azurerm_storage_table" "poison_messages" {
  depends_on           = [time_sleep.wait_storage]
  name                 = "resultWorkerPoisonMessages"
  storage_account_name = azurerm_storage_account.private.name
}

####################################### PUBLIC STORAGE DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "storage_public" {
  resource_id = azurerm_storage_account.public.id
}

resource "azurerm_monitor_diagnostic_setting" "storage_public" {
  name                       = "storageladiagnostics"
  target_resource_id         = azurerm_storage_account.public.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.stamp.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.storage_public.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.storage_public.metrics

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

data "azurerm_monitor_diagnostic_categories" "storage_public_blob" {
  resource_id = "${azurerm_storage_account.public.id}/blobServices/default/"
}

resource "azurerm_monitor_diagnostic_setting" "storage_public_blob" {
  name                       = "storageblobladiagnostics"
  target_resource_id         = "${azurerm_storage_account.public.id}/blobServices/default/"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.stamp.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.storage_public_blob.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.storage_public_blob.metrics

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

####################################### PRIVATE STORAGE DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "storage_private" {
  resource_id = azurerm_storage_account.private.id
}

resource "azurerm_monitor_diagnostic_setting" "storage_private" {
  name                       = "storageladiagnostics"
  target_resource_id         = azurerm_storage_account.private.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.stamp.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.storage_private.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.storage_private.metrics

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

data "azurerm_monitor_diagnostic_categories" "storage_private_blob" {
  resource_id = "${azurerm_storage_account.private.id}/blobServices/default/"
}

resource "azurerm_monitor_diagnostic_setting" "storage_private_blob" {
  name                       = "storageblobladiagnostics"
  target_resource_id         = "${azurerm_storage_account.private.id}/blobServices/default/"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.stamp.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.storage_private_blob.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.storage_private_blob.metrics

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
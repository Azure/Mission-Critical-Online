resource "azurerm_cosmosdb_account" "main" {
  name                = "${local.prefix}-global-cosmos"
  location            = azurerm_resource_group.global.location
  resource_group_name = azurerm_resource_group.global.name
  offer_type          = "Standard"

  enable_automatic_failover       = true
  enable_multiple_write_locations = true

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  dynamic "geo_location" {
    for_each = var.stamps
    content {
      location          = geo_location.value
      failover_priority = geo_location.key
      zone_redundant    = true
    }
  }

  tags = local.default_tags
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmosdb_database_name
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_cosmosdb_sql_container" "catalogItems" {
  name                = "catalogItems"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_path  = "/id"

  # Enable TTL on the container. This will delete items which TTL has expired.
  default_ttl = -1 # means no documents will be deleted from the container by default. Only if explicitly set on an item.

  indexing_policy {

    excluded_path {
      path = "/description/?"
    }

    excluded_path {
      path = "/imageUrl/?"
    }

    included_path {
      path = "/*"
    }

  }

  autoscale_settings {
    max_throughput = var.cosmosdb_collection_catalogitems_max_autoscale_throughputunits
  }

}

resource "azurerm_cosmosdb_sql_container" "itemComments" {
  name                = "itemComments"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_path  = "/catalogItemId"

  # Enable TTL on the container. This will delete items which TTL has expired.
  default_ttl = -1 # means no documents will be deleted from the container by default. Only if explicitly set on an item.

  indexing_policy {

    excluded_path {
      path = "/text/*"
    }

    included_path {
      path = "/*"
    }

  }

  autoscale_settings {
    max_throughput = var.cosmosdb_collection_itemcomments_max_autoscale_throughputunits
  }

}

resource "azurerm_cosmosdb_sql_container" "itemRating" {
  name                = "itemRatings"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_path  = "/catalogItemId"

  # Enable TTL on the container. This will delete items which TTL has expired.
  default_ttl = -1 # means no documents will be deleted from the container by default. Only if explicitly set on an item.

  autoscale_settings {
    max_throughput = var.cosmosdb_collection_itemratings_max_autoscale_throughputunits
  }

}

####################################### DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "cosmosdb" {
  resource_id = azurerm_cosmosdb_account.main.id
}

resource "azurerm_monitor_diagnostic_setting" "cosmosdb" {
  name                           = "cosmosdbladiagnostics"
  target_resource_id             = azurerm_cosmosdb_account.main.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.global.id
  log_analytics_destination_type = "AzureDiagnostics"

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.cosmosdb.log_category_types

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
    for_each = data.azurerm_monitor_diagnostic_categories.cosmosdb.metrics

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

#### Private Endpoint related resources for ACR
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.stamp.name

  tags = var.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-private-dns-link"
  resource_group_name   = azurerm_resource_group.stamp.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.stamp.id
}

resource "azurerm_private_endpoint" "acr" {
  name                = "${local.prefix}-${local.location_short}-acr-pe"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_dns_zone_group {
    name                 = "privatednsacr"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  private_service_connection {
    name                           = "${local.prefix}-${local.location_short}-acr-privateserviceconnection"
    private_connection_resource_id = data.azurerm_container_registry.global.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  tags = var.default_tags
}

#### Private Endpoint related resources for Cosmos DB
resource "azurerm_private_dns_zone" "cosmosdb" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.stamp.name

  tags = var.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb" {
  name                  = "cosmosdb-private-dns-link"
  resource_group_name   = azurerm_resource_group.stamp.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb.name
  virtual_network_id    = azurerm_virtual_network.stamp.id
}

resource "azurerm_private_endpoint" "cosmosdb" {
  name                = "${local.prefix}-${local.location_short}-cosmosdb-pe"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_dns_zone_group {
    name                 = "privatednscosmosdb"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmosdb.id]
  }

  private_service_connection {
    name                           = "cosmosdb-privateserviceconnection"
    private_connection_resource_id = data.azurerm_cosmosdb_account.global.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  tags = var.default_tags
}

#### Private Endpoint related resources for Event Hub Namespace / Servicebus
resource "azurerm_private_dns_zone" "servicebus" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.stamp.name

  tags = var.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "servicebus" {
  name                  = "servicebus-private-dns-link"
  resource_group_name   = azurerm_resource_group.stamp.name
  private_dns_zone_name = azurerm_private_dns_zone.servicebus.name
  virtual_network_id    = azurerm_virtual_network.stamp.id
}

resource "azurerm_private_endpoint" "eventhub_namespace" {
  name                = "${local.prefix}-${local.location_short}-evhns-pe"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_dns_zone_group {
    name                 = "privatednsservicebus"
    private_dns_zone_ids = [azurerm_private_dns_zone.servicebus.id]
  }

  private_service_connection {
    name                           = "evhns-privateserviceconnection"
    private_connection_resource_id = azurerm_eventhub_namespace.stamp.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  tags = var.default_tags
}

#### Private Endpoint related resources for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.stamp.name

  tags = var.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "keyvault-private-dns-link"
  resource_group_name   = azurerm_resource_group.stamp.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.stamp.id
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "${local.prefix}-${local.location_short}-keyvault-pe"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_dns_zone_group {
    name                 = "privatednskeyvault"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }

  private_service_connection {
    name                           = "${local.prefix}-${local.location_short}-keyvault-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.stamp.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = var.default_tags
}

#### Private Endpoint related resources for Storage
resource "azurerm_private_dns_zone" "blob_storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.stamp.name

  tags = var.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_storage" {
  name                  = "storage-blob-private-dns-link"
  resource_group_name   = azurerm_resource_group.stamp.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_storage.name
  virtual_network_id    = azurerm_virtual_network.stamp.id
}

resource "azurerm_private_endpoint" "blob_storage" {
  name                = "${local.prefix}-${local.location_short}-storage-blob-pe"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_dns_zone_group {
    name                 = "privatednsstorageblob"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_storage.id]
  }

  private_service_connection {
    name                           = "${local.prefix}-${local.location_short}-storage-blob-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.private.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = var.default_tags
}

resource "azurerm_private_dns_zone" "table_storage" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.stamp.name

  tags = var.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "table_storage" {
  name                  = "storage-table-private-dns-link"
  resource_group_name   = azurerm_resource_group.stamp.name
  private_dns_zone_name = azurerm_private_dns_zone.table_storage.name
  virtual_network_id    = azurerm_virtual_network.stamp.id
}

resource "azurerm_private_endpoint" "table_storage" {
  name                = "${local.prefix}-${local.location_short}-storage-table-pe"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_dns_zone_group {
    name                 = "privatednsstoragetable"
    private_dns_zone_ids = [azurerm_private_dns_zone.table_storage.id]
  }

  private_service_connection {
    name                           = "${local.prefix}-${local.location_short}-storage-table-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.private.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }

  tags = var.default_tags
}

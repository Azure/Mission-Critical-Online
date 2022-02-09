# Create PL and PE for PGDB backend
resource "azurerm_private_dns_zone" "pgdb" {
  for_each            = var.stamps
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg[each.key].name
  tags                = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "pgdb" {
  for_each              = var.stamps
  name                  = "${local.prefix}-${substr(each.value["location"], 0, 5)}-pg-pl"
  resource_group_name   = azurerm_resource_group.rg[each.key].name
  private_dns_zone_name = azurerm_private_dns_zone.pgdb[each.key].name
  virtual_network_id    = azurerm_virtual_network.vnet[each.key].id
}

resource "azurerm_private_endpoint" "pgdb" {
  for_each            = var.stamps
  name                = "${local.prefix}-${substr(each.value["location"], 0, 5)}-pg-pe"
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  subnet_id           = azurerm_subnet.snet_datastores[each.key].id

  private_dns_zone_group {
    name                 = "${local.prefix}-${substr(each.value["location"], 0, 5)}-privatepgdb"
    private_dns_zone_ids = [azurerm_private_dns_zone.pgdb[each.key].id]
  }

  private_service_connection {
    name                           = "${local.prefix}-${substr(each.value["location"], 0, 5)}-pg-psconn"
    private_connection_resource_id = each.value["db_primary"] ? azurerm_postgresql_server.pgprimary.id : azurerm_postgresql_server.pgreplica.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
  tags = local.default_tags
}

# Project PE into VNET of secondary region. This approach enables cross-regional connectivity for the App Service without deploying a VPN GW.
resource "azurerm_private_endpoint" "pgdb_pe_project" {
  name                = "${local.prefix}-secondary-privatepgdb"
  location            = azurerm_resource_group.rg["secondary"].location
  resource_group_name = azurerm_resource_group.rg["secondary"].name
  subnet_id           = azurerm_subnet.snet_datastores["secondary"].id

  private_dns_zone_group {
    name                 = "${local.prefix}-secondary-privatepgdb"
    private_dns_zone_ids = [azurerm_private_dns_zone.pgdb["secondary"].id]
  }

  private_service_connection {
    name                           = "${local.prefix}-secondary-pg-psconn"
    private_connection_resource_id = azurerm_postgresql_server.pgprimary.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
  tags = local.default_tags
}
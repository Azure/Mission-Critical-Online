# Deploy primary database server
resource "azurerm_postgresql_server" "pgprimary" {
  name                         = "${local.prefix}-${substr(var.stamps[0], 0, 5)}-pgdb"
  location                     = azurerm_resource_group.rg[0].location
  resource_group_name          = azurerm_resource_group.rg[0].name
  administrator_login          = var.db_admin_user
  administrator_login_password = random_password.postgres_password.result
  sku_name                     = "GP_Gen5_2"
  version                      = 11
  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  public_network_access_enabled    = false
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
}

# Create database on the primary server. This block is executed for primary alone because we are using "replica" creation method for secondary which by default copies
# across all the databases from primary.
resource "azurerm_postgresql_database" "pgdb" {
  name                = "grafana"
  resource_group_name = azurerm_resource_group.rg.0.name
  server_name         = azurerm_postgresql_server.pgprimary.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# Separate resource definition for secondary PGDB as it must be deployed only once parent (primary DB) has been deployed.
resource "azurerm_postgresql_server" "pgreplica" {
  for_each = { for k, v in local.stamps : k => v if k != "0" } # cut of the first region from the list of regions as that is the primary

  depends_on                       = [azurerm_postgresql_database.pgdb]
  name                             = "${local.prefix}-${substr(each.value, 0, 5)}-pgdb"
  location                         = azurerm_resource_group.rg[each.key].location
  resource_group_name              = azurerm_resource_group.rg[each.key].name
  create_mode                      = "Replica"
  creation_source_server_id        = azurerm_postgresql_server.pgprimary.id
  administrator_login              = var.db_admin_user
  administrator_login_password     = random_password.postgres_password.result
  sku_name                         = azurerm_postgresql_server.pgprimary.sku_name
  version                          = azurerm_postgresql_server.pgprimary.version
  storage_mb                       = azurerm_postgresql_server.pgprimary.storage_mb
  backup_retention_days            = azurerm_postgresql_server.pgprimary.backup_retention_days
  geo_redundant_backup_enabled     = azurerm_postgresql_server.pgprimary.geo_redundant_backup_enabled
  auto_grow_enabled                = azurerm_postgresql_server.pgprimary.auto_grow_enabled
  public_network_access_enabled    = azurerm_postgresql_server.pgprimary.public_network_access_enabled
  ssl_enforcement_enabled          = azurerm_postgresql_server.pgprimary.ssl_enforcement_enabled
  ssl_minimal_tls_version_enforced = azurerm_postgresql_server.pgprimary.ssl_minimal_tls_version_enforced
}
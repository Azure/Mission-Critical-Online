# Deploy primary database server
resource "azurerm_postgresql_server" "pgprimary" {
  name                         = "${local.prefix}-${substr(var.stamps["primary"].location, 0, 5)}-pgdb"
  location                     = azurerm_resource_group.rg["primary"].location
  resource_group_name          = azurerm_resource_group.rg["primary"].name
  administrator_login          = var.db_admin_user
  administrator_login_password = random_password.postgres_password.result
  sku_name                     = var.db_sku_name
  version                      = var.db_ver
  storage_mb                   = var.db_storage_mb
  backup_retention_days        = var.db_bkp_retention
  geo_redundant_backup_enabled = var.db_geo_bkp
  auto_grow_enabled            = var.db_auto_grow

  #VNET rules work once this option is set to TRUE. Refer https://github.com/hashicorp/terraform-provider-azurerm/issues/8534
  public_network_access_enabled    = var.db_net_pub_access
  ssl_enforcement_enabled          = var.db_ssl
  ssl_minimal_tls_version_enforced = var.db_ssl_ver
}

# Create database on the primary server. This block is executed for primary alone because we are using "replica" creation method for secondary which by default copies
# across all the databases from primary. 
resource "azurerm_postgresql_database" "pgdb" {
  name                = "grafana"
  resource_group_name = azurerm_resource_group.rg["primary"].name
  server_name         = azurerm_postgresql_server.pgprimary.name
  charset             = var.db_charset
  collation           = var.db_collation
}

# Separate resource definition for secondary PGDB as it must be deployed only once parent (primary DB) has been deployed.
resource "azurerm_postgresql_server" "pgreplica" {
  name                             = "${local.prefix}-${substr(var.stamps["secondary"].location, 0, 5)}-pgdb"
  location                         = azurerm_resource_group.rg["secondary"].location
  resource_group_name              = azurerm_resource_group.rg["secondary"].name
  create_mode                      = "Replica"
  creation_source_server_id        = azurerm_postgresql_server.pgprimary.id
  administrator_login              = var.db_admin_user
  administrator_login_password     = random_password.postgres_password.result
  sku_name                         = var.db_sku_name
  version                          = var.db_ver
  storage_mb                       = var.db_storage_mb
  backup_retention_days            = var.db_bkp_retention
  geo_redundant_backup_enabled     = var.db_geo_bkp
  auto_grow_enabled                = var.db_auto_grow
  public_network_access_enabled    = var.db_net_pub_access
  ssl_enforcement_enabled          = var.db_ssl
  ssl_minimal_tls_version_enforced = var.db_ssl_ver
  depends_on                       = [azurerm_postgresql_server.pgprimary, azurerm_postgresql_database.pgdb]
}
resource "azurerm_app_service_plan" "asp" {
  for_each            = var.stamps
  name                = "${local.prefix}-${substr(each.value["location"], 0, 5)}-asp"
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }

  tags = local.default_tags

}

resource "azurerm_app_service" "appservice" {
  for_each            = var.stamps
  name                = "${local.prefix}-${substr(each.value["location"], 0, 5)}-app"
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  app_service_plan_id = azurerm_app_service_plan.asp[each.key].id

  identity {
    type = "SystemAssigned"
  }

  // these env variables are specific to postgres backend supported by grafana
  app_settings = {
    "GF_DATABASE_TYPE"     = "postgres"
    "GF_DATABASE_HOST"     = "${each.key == "primary" ? azurerm_postgresql_server.pgprimary.name : azurerm_postgresql_server.pgreplica.name}.postgres.database.azure.com"
    "GF_DATABASE_NAME"     = azurerm_postgresql_database.pgdb.name
    "GF_DATABASE_USER"     = "${var.db_admin_user}@${each.key == "primary" ? azurerm_postgresql_server.pgprimary.name : azurerm_postgresql_server.pgreplica.name}"
    "GF_DATABASE_PASSWORD" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.postgres_password[each.key].id})"
    "GF_DATABASE_SSL_MODE" = "require"

    "GRAFANA_USERNAME"           = "alwayson"
    "GRAFANA_PASSWORD"           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.grafana_password[each.key].id})"
    "AZURE_DEFAULT_SUBSCRIPTION" = data.azurerm_subscription.current.subscription_id
    "WEBSITES_PORT"              = "3000"
    "WEBSITE_VNET_ROUTE_ALL"     = "1"
  }

  site_config {
    always_on                            = true
    scm_use_main_ip_restriction          = true
    linux_fx_version                     = "DOCKER|${var.wapp_container_image}"
    app_command_line                     = "docker run -p 3000:3000 -d --name=grafana ${var.wapp_container_image}"
    acr_use_managed_identity_credentials = true

    ip_restriction {
      service_tag = "AzureFrontDoor.Backend"
      name        = "restrictToAfd"
      priority    = 500
      action      = "Allow"
      headers {
        x_azure_fdid = ["${var.frontdoor_header_id}"]
      }
    }

  }

  tags = local.default_tags
}

# This is required to enable outbound connectivity from app service.
resource "azurerm_app_service_virtual_network_swift_connection" "vnetintegrationconnection" {
  for_each       = var.stamps
  app_service_id = azurerm_app_service.appservice[each.key].id
  subnet_id      = azurerm_subnet.snet_app_outbound[each.key].id
}
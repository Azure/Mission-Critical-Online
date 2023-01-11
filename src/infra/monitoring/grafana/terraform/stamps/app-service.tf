resource "azurerm_service_plan" "asp" {
  for_each            = local.stamps
  name                = "${local.prefix}-${substr(each.value, 0, 5)}-asp"
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  os_type             = "Linux"
  sku_name            = "P1v2"

  zone_balancing_enabled = false # Balance Service Plan across Availability Zones (AZs)
  # This is currently disabled as the database backend is not using AZs.

  tags = local.default_tags
}

resource "azurerm_linux_web_app" "appservice" {
  for_each            = local.stamps
  name                = "${local.prefix}-${substr(each.value, 0, 5)}-app"
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  service_plan_id     = azurerm_service_plan.asp[each.key].id
  https_only          = true

  virtual_network_subnet_id = azurerm_subnet.snet_app_outbound[each.key].id

  identity {
    type = "SystemAssigned"
  }

  // these env variables are specific to postgres backend supported by grafana
  app_settings = {
    "GF_DATABASE_TYPE"     = "postgres"
    "GF_DATABASE_HOST"     = "${each.key == "0" ? azurerm_postgresql_server.pgprimary.name : azurerm_postgresql_server.pgreplica[each.key].name}.privatelink.postgres.database.azure.com"
    "GF_DATABASE_NAME"     = azurerm_postgresql_database.pgdb.name
    "GF_DATABASE_USER"     = "${var.db_admin_user}@${each.key == "0" ? azurerm_postgresql_server.pgprimary.name : azurerm_postgresql_server.pgreplica[each.key].name}"
    "GF_DATABASE_PASSWORD" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.postgres_password[each.key].id})"
    "GF_DATABASE_SSL_MODE" = "require"

    "GF_AUTH_AZUREAD_ENABLED"        = "true"
    "GF_AUTH_AZUREAD_ALLOW_SIGN_UP"  = "true"
    "GF_AUTH_AZUREAD_CLIENT_ID"      = var.auth_client_id
    "GF_AUTH_AZUREAD_CLIENT_SECRET"  = var.auth_client_secret
    "GF_AUTH_AZUREAD_SCOPES"         = "openid email profile"
    "GF_AUTH_AZUREAD_AUTH_URL"       = "https://login.microsoftonline.com/${var.auth_client_tenant}/oauth2/v2.0/authorize"
    "GF_AUTH_AZUREAD_TOKEN_URL"      = "https://login.microsoftonline.com/${var.auth_client_tenant}/oauth2/v2.0/token"
    "GF_AUTH_AZUREAD_ALLOWED_GROUPS" = var.auth_group_id

    "GF_SERVER_DOMAIN" = var.frontdoor_fqdn

    "GF_SERVER_ROOT_URL"            = "https://${var.frontdoor_fqdn}/"
    "GF_SERVER_SERVE_FROM_SUB_PATH" = "true"

    "GF_SECURITY_CSRF_ADDITIONAL_HEADERS" = "X-FORWARDED-HOST"
    "GF_SECURITY_CSRF_TRUSTED_ORIGINS"    = "https://${var.frontdoor_fqdn}"

    "GRAFANA_USERNAME"           = "alwayson"
    "GRAFANA_PASSWORD"           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.grafana_password[each.key].id})"
    "AZURE_DEFAULT_SUBSCRIPTION" = data.azurerm_subscription.current.subscription_id

    "WEBSITES_PORT"          = "3000"
    "WEBSITE_VNET_ROUTE_ALL" = "1"
  }

  site_config {
    always_on                               = true
    scm_use_main_ip_restriction             = true
    container_registry_use_managed_identity = true

    application_stack {
      docker_image     = split(":", var.wapp_container_image)[0]
      docker_image_tag = split(":", var.wapp_container_image)[1] != "" ? split(":", var.wapp_container_image)[1] : "latest"
    }

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

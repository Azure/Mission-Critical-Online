resource "azurerm_container_group" "master" {
  count               = var.locust_workers >= 1 ? 1 : 0
  name                = "${local.prefix}-loadtest-master-ci"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name
  ip_address_type     = "Public"
  dns_name_label      = "${local.prefix}-loadtest-master"
  os_type             = "Linux"

  restart_policy = "Never" # Locust stops the master once the test is done. A restart_policy other than 'Never' and ACI will restart the container - and the test would run again from start.

  container {
    name   = "${local.prefix}-loadtest-master-ci"
    image  = var.locust_container_image
    cpu    = "1"
    memory = "1"

    commands = [
      "locust"
    ]

    environment_variables = merge(local.environment_variables_common, local.environment_variables_master)

    secure_environment_variables = {
      "LOCUST_WEB_AUTH" = "locust:${azurerm_key_vault_secret.locustsecret.value}"
    }

    volume {
      name       = "locust"
      mount_path = "/home/locust/locust"

      storage_account_key  = azurerm_storage_account.deployment.primary_access_key
      storage_account_name = azurerm_storage_account.deployment.name
      share_name           = azurerm_storage_share.locust.name
    }

    ports {
      port     = "8089" # port for the Web UI
      protocol = "TCP"
    }

    ports {
      port     = "5557"
      protocol = "TCP"
    }

  }

  tags = local.default_tags
}

resource "azurerm_container_group" "worker" {
  count               = var.locust_workers
  name                = "${local.prefix}-locust-worker-${count.index}-ci"
  location            = var.locust_worker_locations[count.index % length(var.locust_worker_locations)]
  resource_group_name = azurerm_resource_group.deployment.name
  ip_address_type     = "Public"
  os_type             = "Linux"

  restart_policy = "Always"

  container {
    name   = "${local.prefix}-worker-${count.index}-ci"
    image  = var.locust_container_image
    cpu    = "2"
    memory = "2"

    commands = [
      "locust"
    ]

    environment_variables = merge(
      { "LOCUST_MASTER_NODE_HOST" = azurerm_container_group.master.0.fqdn },
      local.environment_variables_common, local.environment_variables_worker
    )

    volume {
      name       = "locust"
      mount_path = "/home/locust/locust"

      storage_account_key  = azurerm_storage_account.deployment.primary_access_key
      storage_account_name = azurerm_storage_account.deployment.name
      share_name           = azurerm_storage_share.locust.name
    }

    ports {
      port     = 8089
      protocol = "TCP"
    }

  }

  tags = local.default_tags
}
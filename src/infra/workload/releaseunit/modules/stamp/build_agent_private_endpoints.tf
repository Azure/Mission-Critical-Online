## Build Agent Private Endpoints
# IMPORTANT: These are only deployed when var.private_mode is set to true!
# This also requires the variables var.buildagent_resource_group_name and var.buildagent_vnet_name to be set

### AKS ###
resource "azurerm_private_endpoint" "buildagent_aks" {
  count               = var.private_mode ? 1 : 0
  name                = "${local.prefix}-${local.location_short}-built-agent-aks-pe"
  location            = data.azurerm_resource_group.buildagent.0.location
  resource_group_name = data.azurerm_resource_group.buildagent.0.name
  subnet_id           = "${data.azurerm_virtual_network.buildagent.0.id}/subnets/private-endpoints-snet"

  private_service_connection {
    name                           = "${local.prefix}-${local.location_short}-aks-buildagent-privateserviceconnection"
    private_connection_resource_id = azurerm_kubernetes_cluster.stamp.id
    is_manual_connection           = false
    subresource_names              = ["management"]
  }

  tags = var.default_tags
}

# It is a known issue that AKS cannot automatically update the DNS records for Private Endpoints
# Therefore we manually create an A record in the private DNS zone that was created in the build agent resource group beforehand
resource "azurerm_private_dns_a_record" "aks" {
  count               = var.private_mode ? 1 : 0
  name                = regex("^(.+)\\.azmk8s\\.io", azurerm_kubernetes_cluster.stamp.private_fqdn)[0] # extract first parts of the DNS name
  zone_name           = "azmk8s.io"
  resource_group_name = data.azurerm_resource_group.buildagent.0.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.buildagent_aks.0.private_service_connection.0.private_ip_address]
}

### END AKS ###

### Key Vault ###
resource "azurerm_private_endpoint" "buildagent_keyvault" {
  count               = var.private_mode ? 1 : 0
  name                = "${local.prefix}-${local.location_short}-built-agent-keyvault-pe"
  location            = data.azurerm_resource_group.buildagent.0.location
  resource_group_name = data.azurerm_resource_group.buildagent.0.name
  subnet_id           = "${data.azurerm_virtual_network.buildagent.0.id}/subnets/private-endpoints-snet"

  private_dns_zone_group {
    name                 = "privatednskeyvault"
    private_dns_zone_ids = ["${data.azurerm_resource_group.buildagent.0.id}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]
  }

  private_service_connection {
    name                           = "${local.prefix}-${local.location_short}-keyvault-buildagent-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.stamp.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = var.default_tags
}

### END Key Vault ###

### Storage Account ###
resource "azurerm_private_endpoint" "buildagent_storage_blob" {
  count               = var.private_mode ? 1 : 0
  name                = "${local.prefix}-${local.location_short}-built-agent-storage-blob-pe"
  location            = data.azurerm_resource_group.buildagent.0.location
  resource_group_name = data.azurerm_resource_group.buildagent.0.name
  subnet_id           = "${data.azurerm_virtual_network.buildagent.0.id}/subnets/private-endpoints-snet"

  private_dns_zone_group {
    name                 = "privatednsstorageblob"
    private_dns_zone_ids = ["${data.azurerm_resource_group.buildagent.0.id}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
  }

  private_service_connection {
    name                           = "${local.prefix}-${local.location_short}-storage-blob-buildagent-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.private.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = var.default_tags
}

resource "azurerm_private_endpoint" "buildagent_storage_table" {
  count               = var.private_mode ? 1 : 0
  name                = "${local.prefix}-${local.location_short}-built-agent-storage-table-pe"
  location            = data.azurerm_resource_group.buildagent.0.location
  resource_group_name = data.azurerm_resource_group.buildagent.0.name
  subnet_id           = "${data.azurerm_virtual_network.buildagent.0.id}/subnets/private-endpoints-snet"

  private_dns_zone_group {
    name                 = "privatednsstoragetable"
    private_dns_zone_ids = ["${data.azurerm_resource_group.buildagent.0.id}/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net"]
  }

  private_service_connection {
    name                           = "${local.prefix}-${local.location_short}-storage-table-buildagent-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.private.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }

  tags = var.default_tags
}

### END Storage Account ###
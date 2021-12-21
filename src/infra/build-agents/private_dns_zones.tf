# This provisions a number of private DNS zones for all the types of private endpoints we expect to be created later during actual environment deployments
# Those private endpoints will then also add and remove actual DNS entries to the zones

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.deployment.name

  tags = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "keyvault-private-dns-link"
  resource_group_name   = azurerm_resource_group.deployment.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.deployment.id
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.deployment.name

  tags = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-private-dns-link"
  resource_group_name   = azurerm_resource_group.deployment.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.deployment.id
}


# Note: Using this high-level zone means that the private build agents cannot reach any non-private link AKS clusters anymore!
# But it is easier to maintain than using a separate zone per region ("privatelink.eastus2.azmk8s.io")
resource "azurerm_private_dns_zone" "aks" {
  name                = "azmk8s.io"
  resource_group_name = azurerm_resource_group.deployment.name

  tags = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "aks-private-dns-link"
  resource_group_name   = azurerm_resource_group.deployment.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.deployment.id
}


resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.deployment.name

  tags = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  name                  = "storage-blob-private-dns-link"
  resource_group_name   = azurerm_resource_group.deployment.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.deployment.id
}

resource "azurerm_private_dns_zone" "storage_table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.deployment.name

  tags = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_table" {
  name                  = "storage-table-private-dns-link"
  resource_group_name   = azurerm_resource_group.deployment.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_table.name
  virtual_network_id    = azurerm_virtual_network.deployment.id
}
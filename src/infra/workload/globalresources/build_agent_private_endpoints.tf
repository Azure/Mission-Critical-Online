## Self-Hosted Build Agent Private Endpoints
# IMPORTANT: These are only deployed when var.private_mode is set to true!
# This also requires the variables var.buildagent_resource_group_name and var.buildagent_vnet_name to be set

resource "azurerm_private_endpoint" "buildagent_acr" {
  count               = var.private_mode ? 1 : 0 # This is only deployed when var.private_mode is set to true!
  name                = "${local.prefix}-built-agent-acr-pe"
  location            = data.azurerm_resource_group.buildagent.0.location
  resource_group_name = data.azurerm_resource_group.buildagent.0.name
  subnet_id           = "${data.azurerm_virtual_network.buildagent.0.id}/subnets/private-endpoints-snet"

  private_dns_zone_group {
    name                 = "privatednsacr"
    private_dns_zone_ids = ["${data.azurerm_resource_group.buildagent.0.id}/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io"]
  }

  private_service_connection {
    name                           = "${local.prefix}-acr-buildagent-privateserviceconnection"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  tags = local.default_tags
}
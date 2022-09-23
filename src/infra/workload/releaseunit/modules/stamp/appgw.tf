resource "azurerm_application_gateway" "stamp" {
  name                 = "${local.prefix}-${local.location_short}-appgw"
  location             = azurerm_resource_group.stamp.location
  resource_group_name  = azurerm_resource_group.stamp.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw_frontend.id
  }

  frontend_port {
    name = "${azurerm_virtual_network.stamp.name}-feport"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${azurerm_virtual_network.stamp.name}-feip"
    public_ip_address_id = azurerm_public_ip.ingress.id
  }

  backend_address_pool {
    name = "${azurerm_virtual_network.stamp.name}-beap"
  }

  backend_http_settings {
    name                  = "${azurerm_virtual_network.stamp.name}-be-htst"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "${azurerm_virtual_network.stamp.name}-httplstn"
    frontend_ip_configuration_name = "${azurerm_virtual_network.stamp.name}-feip"
    frontend_port_name             = "${azurerm_virtual_network.stamp.name}-feport"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${azurerm_virtual_network.stamp.name}-rqrt"
    rule_type                  = "Basic"
    http_listener_name         = "${azurerm_virtual_network.stamp.name}-httplstn"
    backend_address_pool_name  = "${azurerm_virtual_network.stamp.name}-beap"
    backend_http_settings_name = "${azurerm_virtual_network.stamp.name}-be-htst"

    priority = 1
  }
}
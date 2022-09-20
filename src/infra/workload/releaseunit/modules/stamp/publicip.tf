# Static Public IP which will later be used for ingress traffic.
resource "azurerm_public_ip" "ingress" {
  name                = "${local.prefix}-${local.location_short}-ingress-pip"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  sku                 = "Standard"
  allocation_method   = "Static"

  domain_name_label = "${local.prefix}-cluster"

  zones = ["1", "2", "3"]

  tags = var.default_tags
}
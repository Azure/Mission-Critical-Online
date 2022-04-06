# Static Public IP for APIM
resource "azurerm_public_ip" "apim" {
  name                = "${local.prefix}-${local.location_short}-apim-pip"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  sku                 = "Standard"
  allocation_method   = "Static"

  domain_name_label = "${local.prefix}-apim"

  zones = ["1", "2", "3"]

  tags = var.default_tags
}
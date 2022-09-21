resource "azurerm_shared_image_gallery" "main" {
  name                = "${local.prefix}-image-gallery"
  location            = azurerm_resource_group.global.location
  resource_group_name = azurerm_resource_group.global.name
  description         = "Shared images and things."

  tags = local.default_tags
}
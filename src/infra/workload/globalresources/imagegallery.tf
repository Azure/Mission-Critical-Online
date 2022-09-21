resource "azurerm_shared_image_gallery" "main" {
  name                = "${local.prefix}_image_gallery"
  location            = azurerm_resource_group.global.location
  resource_group_name = azurerm_resource_group.global.name
  description         = "Shared images and things."

  tags = local.default_tags
}


resource "azurerm_shared_image" "ubuntu2004" {
  name                = "ubuntu2004"
  gallery_name        = azurerm_shared_image_gallery.main.name
  resource_group_name = azurerm_resource_group.global.name
  location            = azurerm_resource_group.global.location
  os_type             = "Linux"

  identifier {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
  }
}
resource "azurerm_storage_account" "regional" {
  name                     = "${var.prefix}${local.location_short}lgstg"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = false

  tags = var.default_tags
}

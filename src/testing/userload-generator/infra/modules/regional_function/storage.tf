resource "azurerm_storage_account" "regional" {
  name                     = "${var.prefix}${local.location_short}lgstg"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.default_tags
}

resource "azurerm_storage_account" "master" {
  name                     = "${local.prefix}masterlgstg"
  location                 = azurerm_resource_group.deployment.location
  resource_group_name      = azurerm_resource_group.deployment.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = false

  tags = local.default_tags
}

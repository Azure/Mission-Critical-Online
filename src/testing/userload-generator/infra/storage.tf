resource "azurerm_storage_account" "master" {
  name                     = "${local.prefix}masterlgstg"
  location                 = azurerm_resource_group.deployment.location
  resource_group_name      = azurerm_resource_group.deployment.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.default_tags
}

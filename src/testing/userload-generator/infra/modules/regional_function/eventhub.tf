resource "azurerm_eventhub_namespace" "regional" {
  name                = "${var.prefix}-loadgen-${var.location}-evhns"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Basic"
  capacity            = 1
  tags                = var.default_tags
}

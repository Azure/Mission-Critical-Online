# The next data sources are only relevant when running in private mode with a self-hosted build agent. They are used to deploy Private Endpoints for the build agent
data "azurerm_resource_group" "buildagent" {
  count = var.private_mode ? 1 : 0
  name  = var.buildagent_resource_group_name
}

data "azurerm_virtual_network" "buildagent" {
  count               = var.private_mode ? 1 : 0
  name                = var.buildagent_vnet_name
  resource_group_name = var.buildagent_resource_group_name
}
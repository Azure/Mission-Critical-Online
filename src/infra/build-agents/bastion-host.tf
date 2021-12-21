# Public IP address required by Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "${local.prefix}-bastion-pip"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.default_tags
}

# Bastion host which will be used to connect to the jump servers
resource "azurerm_bastion_host" "bastion" {
  name                = "${local.prefix}-bastionhost"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = local.default_tags
}
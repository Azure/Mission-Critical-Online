# Deploy foundational networking capabilities such as VNETs; subnets and peerings. 

module "subnet_addrs" {
  source   = "hashicorp/subnets/cidr"
  for_each = var.stamps

  base_cidr_block = each.value["vnet_address_space"]
  networks = [
    {
      name     = "app_outbound"
      new_bits = 8
    },
    {
      name     = "postgres"
      new_bits = 8
    }
  ]
}

resource "azurerm_virtual_network" "vnet" {
  for_each            = var.stamps
  name                = "${local.prefix}-${substr(each.value["location"], 0, 5)}-vnet"
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
  address_space       = [module.subnet_addrs[each.key].base_cidr_block]

  tags = local.default_tags
}

# Delegated subnet for web app. This is required to enable outbound conectivity from the app to PGDB backend.
resource "azurerm_subnet" "snet_app_outbound" {
  for_each                                       = var.stamps
  name                                           = "${local.prefix}-${substr(each.value["location"], 0, 5)}-app-snet"
  address_prefixes                               = [module.subnet_addrs[each.key].network_cidr_blocks["app_outbound"]]
  virtual_network_name                           = azurerm_virtual_network.vnet[each.key].name
  resource_group_name                            = azurerm_resource_group.rg[each.key].name
  enforce_private_link_endpoint_network_policies = true
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# NSG - Assign default nsg to snet_app_outbound subnet
resource "azurerm_subnet_network_security_group_association" "snet_app_outbound_nsg" {
  for_each                  = var.stamps
  subnet_id                 = azurerm_subnet.snet_app_outbound[each.key].id
  network_security_group_id = azurerm_network_security_group.default[each.key].id
}

# Dedicated subnet for all backend datastores including PGDB.
resource "azurerm_subnet" "snet_datastores" {
  for_each                                       = var.stamps
  name                                           = "${local.prefix}-${substr(each.value["location"], 0, 5)}-pgdb-snet"
  address_prefixes                               = [module.subnet_addrs[each.key].network_cidr_blocks["postgres"]]
  virtual_network_name                           = azurerm_virtual_network.vnet[each.key].name
  resource_group_name                            = azurerm_resource_group.rg[each.key].name
  enforce_private_link_endpoint_network_policies = true
}

# NSG - Assign default nsg to snet_datastores subnet
resource "azurerm_subnet_network_security_group_association" "snet_datastores_nsg" {
  for_each                  = var.stamps
  subnet_id                 = azurerm_subnet.snet_datastores[each.key].id
  network_security_group_id = azurerm_network_security_group.default[each.key].id
}

# Default Network Security Group (nsg) definition
# Allows outbound and intra-vnet/cross-subnet communication
resource "azurerm_network_security_group" "default" {
  for_each            = var.stamps
  name                = "${local.prefix}-${substr(each.value["location"], 0, 5)}-nsg"
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name

  # not specifying any security_rules {} will create Azure's default set of NSG rules
  # it allows intra-vnet communication and outbound public internet access

  tags = local.default_tags
}
# Dynamically calculate subnet addresses from the overall address space. Assumes (at least) a /22 address space
# Uses the Hashicopr module "CIDR subnets" https://registry.terraform.io/modules/hashicorp/subnets/cidr/latest
locals {
  netmask = tonumber(split("/", var.vnet_address_space)[1]) # Take the last part from the address space 10.0.0.0/16 => 16
}

module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.vnet_address_space
  networks = [
    {
      name     = "kubernetes"
      new_bits = 22 - local.netmask # For AKS we want a /22 sized subnet. So we calculate based on the provided input address space
    },
    {
      name     = "aks-lb"
      new_bits = 29 - local.netmask # Subnet for internal AKS load balancer
    },
    {
      name     = "apim"
      new_bits = 28 - local.netmask # Subnet for API Management
    }
    # More subnets can be added here and terraform will dynamically calculate their CIDR ranges
  ]
}

# Azure Virtual Network Deployment
resource "azurerm_virtual_network" "stamp" {
  name                = "${local.prefix}-${local.location_short}-vnet"
  resource_group_name = azurerm_resource_group.stamp.name
  location            = azurerm_resource_group.stamp.location
  address_space       = [module.subnet_addrs.base_cidr_block]

  # For production workloads we recommend to enable DDoS protection Standard plan when exposing your AKS ingress on public IPs
  # You can link this to an existing DDoS protection plan or create a new one
  # To enable this, fetch your shared ddos plan resource id and add it as a variable to the terraform definition
  #
  # ddos_protection_plan {
  #   id     = var.ddos_protection_plan_id
  #   enable = true
  # }

  tags = var.default_tags
}

# Default Network Security Group (nsg) definition
# Allows outbound and intra-vnet/cross-subnet communication
resource "azurerm_network_security_group" "default" {
  name                = "${local.prefix}-${local.location_short}-nsg"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name

  # not specifying any security_rules {} will create Azure's default set of NSG rules
  # it allows intra-vnet communication and outbound public internet access

  tags = var.default_tags
}

# Subnet for Kubernetes nodes and pods
resource "azurerm_subnet" "kubernetes" {
  name                 = "kubernetes-snet"
  resource_group_name  = azurerm_resource_group.stamp.name
  virtual_network_name = azurerm_virtual_network.stamp.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["kubernetes"]]
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.AzureCosmosDB",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry",
    "Microsoft.EventHub"
  ]
}

# NSG - Assign default nsg to kubernetes-snet subnet
resource "azurerm_subnet_network_security_group_association" "kubernetes_default_nsg" {
  subnet_id                 = azurerm_subnet.kubernetes.id
  network_security_group_id = azurerm_network_security_group.default.id
}

# Subnet for aks internal lb
resource "azurerm_subnet" "aks_lb" {
  name                 = "aks-lb-snet"
  resource_group_name  = azurerm_resource_group.stamp.name
  virtual_network_name = azurerm_virtual_network.stamp.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["aks-lb"]]
}

# NSG - Assign default nsg to aks-lb-snet subnet
resource "azurerm_subnet_network_security_group_association" "aks_lb_default_nsg" {
  subnet_id                 = azurerm_subnet.aks_lb.id
  network_security_group_id = azurerm_network_security_group.default.id
}

# Subnet for APIM
resource "azurerm_subnet" "apim" {
  name                 = "apim-snet"
  resource_group_name  = azurerm_resource_group.stamp.name
  virtual_network_name = azurerm_virtual_network.stamp.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["apim"]]
  # The following service endpoints are required by APIM control plane
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.EventHub",
    "Microsoft.ServiceBus"
  ]
}

# Default Network Security Group (nsg) definition
# Allows outbound and intra-vnet/cross-subnet communication
resource "azurerm_network_security_group" "apim" {
  name                = "${local.prefix}-${local.location_short}-apim-nsg"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name

  # not specifying any security_rules {} will create Azure's default set of NSG rules
  # it allows intra-vnet communication and outbound public internet access

  tags = var.default_tags
}

# See here for required NSG rules for APIM:
# https://docs.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#configure-nsg-rules

# Allow HTTPS inbound to APIM
resource "azurerm_network_security_rule" "apim_allow_inbound_https" {
  name                        = "Allow_Inbound_HTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["443"]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Allow inbound traffic from LB to APIM (required for Premium tier)
resource "azurerm_network_security_rule" "apim_allow_inbound_lb" {
  name                        = "Allow_Inbound_LB"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["6390"]
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.apim.name
}

# Allow HTTPS inbound to APIM
resource "azurerm_network_security_rule" "apim_allow_inbound_apim_control" {
  name                        = "Allow_Inbound_APIM_Control_Plane"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["3443"]
  source_address_prefix       = "ApiManagement"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.stamp.name
  network_security_group_name = azurerm_network_security_group.apim.name
}

resource "azurerm_subnet_network_security_group_association" "apim_nsg" {
  subnet_id                 = azurerm_subnet.apim.id
  network_security_group_id = azurerm_network_security_group.apim.id
}

####################################### DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "vnet" {
  resource_id = azurerm_virtual_network.stamp.id
}

resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "vnetladiagnostics"
  target_resource_id         = azurerm_virtual_network.stamp.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.stamp.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.vnet.logs

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  dynamic "metric" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.vnet.metrics

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }
}

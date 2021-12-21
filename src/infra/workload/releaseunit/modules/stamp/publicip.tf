# Static Public IP which will later be used by AKS for ingress. AKS will assign this to its managed Load Balancer
resource "azurerm_public_ip" "aks_ingress" {
  name                = "${local.prefix}-${local.location_short}-ingress-pip"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  sku                 = "Standard"
  allocation_method   = "Static"

  domain_name_label = "${local.prefix}-cluster"

  tags = var.default_tags
}
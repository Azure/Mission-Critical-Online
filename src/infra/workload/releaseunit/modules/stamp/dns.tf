data "azurerm_dns_zone" "customdomain" {
  count               = var.custom_dns_zone != "" ? 1 : 0
  name                = var.custom_dns_zone
  resource_group_name = var.custom_dns_zone_resourcegroup_name
}

# A record for the AKS ingress controller (points to private IP address of the ingress controller LB)
resource "azurerm_dns_a_record" "cluster_ingress" {
  count               = var.custom_dns_zone != "" ? 1 : 0
  name                = "internal.ingress.${var.location}.${local.prefix}"
  zone_name           = data.azurerm_dns_zone.customdomain[0].name
  resource_group_name = data.azurerm_dns_zone.customdomain[0].resource_group_name
  ttl                 = 3600
  records             = [local.aks_internal_lb_ip_address]
}
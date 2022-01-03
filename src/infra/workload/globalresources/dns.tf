// If a custom domain name is supplied, we are creating a CNAME to point to the Front Door
data "azurerm_dns_zone" "customdomain" {
  count               = var.custom_fqdn != "" ? 1 : 0
  name                = local.custom_domain_name
  resource_group_name = var.custom_dns_zone_resourcegroup_name
}

resource "azurerm_dns_cname_record" "app_subdomain" {
  count               = var.custom_fqdn != "" ? 1 : 0
  name                = local.custom_domain_subdomain
  zone_name           = data.azurerm_dns_zone.customdomain[count.index].name
  resource_group_name = var.custom_dns_zone_resourcegroup_name
  ttl                 = 3600
  record              = local.frontdoor_default_dns_name
}
// If a custom domain name is supplied, we are creating a CNAME to point to the Front Door
data "azurerm_dns_zone" "customdomain" {
  count               = var.custom_fqdn != "" ? 1 : 0
  name                = local.custom_domain_name
  resource_group_name = var.custom_dns_zone_resourcegroup_name
}

resource "azurerm_dns_cname_record" "app_subdomain" {
  count               = var.custom_fqdn != "" ? 1 : 0
  name                = local.custom_domain_subdomain
  zone_name           = data.azurerm_dns_zone.customdomain.0.name
  resource_group_name = var.custom_dns_zone_resourcegroup_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.default.host_name
}

# TXT record for Front Door custom domain validation
resource "azurerm_dns_txt_record" "global" {
  count               = var.custom_fqdn != "" ? 1 : 0
  name                = "_dnsauth.${local.custom_domain_subdomain}"
  zone_name           = data.azurerm_dns_zone.customdomain.0.name
  resource_group_name = data.azurerm_dns_zone.customdomain.0.resource_group_name
  ttl                 = 3600
  record {
    value = azurerm_cdn_frontdoor_custom_domain.global.0.validation_token
  }
}
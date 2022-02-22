locals {

  default_tags = {
    Owner       = "AlwaysOn V-Team"
    Project     = "AlwaysOn Solution Engineering"
    Toolkit     = "Terraform"
    Contact     = var.contact_email
    Environment = var.environment
    Prefix      = var.prefix
    Branch      = var.branch
  }

  location                   = var.stamps[0]                # we use the first location in the list of stamps as the "main" location to root our global resources in
  location_short             = substr(local.location, 0, 9) # shortened location name used for resource naming
  frontdoor_name             = "${lower(local.prefix)}-global-fd"
  frontdoor_default_dns_name = "${local.frontdoor_name}.azurefd.net"
  prefix                     = "${lower(var.prefix)}grafana"

  # var.custom_fqdn is expected to be something like "www.int.myapp.net"
  # custom_domain_subdomain will then be "www"
  custom_domain_subdomain = var.custom_fqdn != "" ? split(".", var.custom_fqdn)[0] : ""

  # custom_domain_name will then be "int.myapp.net"
  custom_domain_name              = trimprefix(var.custom_fqdn, "${local.custom_domain_subdomain}.")
  frontdoor_default_frontend_name = "DefaultFrontendEndpoint"
  frontdoor_custom_frontend_name  = "CustomDomainFrontendEndpoint"
}
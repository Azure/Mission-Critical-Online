locals {

  default_tags = {
    Owner       = "Azure Mission-Critical V-Team"
    Project     = "Azure Mission-Critical Solution Engineering"
    Toolkit     = "Terraform"
    Contact     = var.contact_email
    Environment = var.environment
    Prefix      = var.prefix
    Branch      = var.branch
  }

  location = var.stamps[0] # we use the first location in the list of stamps as the "main" location to root our global resources in, which need it. E.g. Cosmos DB

  frontdoor_name = "${lower(var.prefix)}-global-fd"

  kql_queries = "${path.root}/../../monitoring/queries/global" # directory that contains the kql queries

  prefix = lower(var.prefix)

  # var.custom_fqdn is expected to be something like "www.int.myapp.net"
  # custom_domain_subdomain will then be "www"
  custom_domain_subdomain = var.custom_fqdn != "" ? split(".", var.custom_fqdn)[0] : ""
  # custom_domain_name will then be "int.myapp.net"
  custom_domain_name = trimprefix(var.custom_fqdn, "${local.custom_domain_subdomain}.")

  frontdoor_default_frontend_name = "DefaultFrontendEndpoint"
  frontdoor_custom_frontend_name  = "CustomDomainFrontendEndpoint"

}

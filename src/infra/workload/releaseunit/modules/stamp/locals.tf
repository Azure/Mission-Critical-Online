locals {
  health_blob_name = "stamp.health"

  kql_queries = "${path.root}/../../monitoring/queries/stamp" # directory that contains the kql queries

  # resources in stamp deployments are typically named <prefix>-<locationshort>-<service>
  prefix         = lower(var.prefix)          # prefix used for resource naming
  location_short = substr(var.location, 0, 9) # shortened location name used for resource naming

  global_resource_prefix = regex("^(.+)-global-rg$", var.global_resource_group_name)[0] # extract global resource prefix from the global resource group name

  aks_internal_lb_ip_address = cidrhost(azurerm_subnet.aks_lb.address_prefixes[0], 5) # 5th IP in the subnet as the previous ones are reserved by Azure

  # If custom domain names are used, return this, otherwise the internal IP address of the ingress controller
  aks_ingress_fqdn = var.custom_dns_zone != "" ? trimsuffix(azurerm_dns_a_record.cluster_ingress[0].fqdn, ".") : local.aks_internal_lb_ip_address # remove trailing dot from the FQDN

  apim_tier  = split("_", var.apim_sku)[0] # extract tier from the sku name
  apim_units = split("_", var.apim_sku)[1] # extract tier from the sku name
}

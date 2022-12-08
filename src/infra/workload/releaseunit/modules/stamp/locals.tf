locals {
  health_blob_name = "stamp.health"

  kql_queries = "${path.root}/../../monitoring/queries/stamp" # directory that contains the kql queries

  # resources in stamp deployments are typically named <prefix>-<locationshort>-<service>
  prefix         = lower(var.prefix)          # prefix used for resource naming
  location_short = substr(var.location, 0, 9) # shortened location name used for resource naming

  global_resource_prefix = regex("^(.+)-global-rg$", var.global_resource_group_name)[0] # extract global resource prefix from the global resource group name

  # regions where the creation of federated identity credentials is not supported on user-assigned managed identities
  # https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation-considerations#unsupported-regions-user-assigned-managed-identities
  unsupported_regions = [
    "swedencentral",
    "swedensouth",
    "germanynorth",
    "switzerlandwest",
    "eastasia",
    "qatarcentral"
  ]
}

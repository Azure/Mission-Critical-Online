locals {
  kql_queries = "${path.root}/../../monitoring/queries/stamp" # directory that contains the kql queries

  # resources in stamp deployments are typically named <prefix>-<locationshort>-<service> 
  prefix         = lower(var.prefix)          # prefix used for resource naming
  location_short = substr(var.location, 0, 9) # shortened location name used for resource naming
}

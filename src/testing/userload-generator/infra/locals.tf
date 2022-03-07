locals {
  default_tags = {
    Owner       = "Azure Mission-Critical V-Team"
    Project     = "Azure Mission-Critical Solution Engineering"
    Toolkit     = "Terraform"
    Environment = var.environment
    Prefix      = var.prefix
    CreatedFor  = var.queued_by # typically contains the value of Build.QueuedBy (provided by Azure DevOps)
  }

  prefix = lower(var.prefix)

  location_short = substr(var.location, 0, 9) # shortened location name used for resource naming

  # Get a flat list of all regions
  regions = toset(flatten(values(var.regional_functions_workers)))

  # Builds a map in the form:
  # function_names_per_geo = [
  #    {
  #       FUNCTIONS_AMERICAS = "aointlgeastus2-loadgen-func,aointlgwestus2-loadgen-func"
  #       FUNCTIONS_APAC     = "aointlgaustralia-loadgen-func,aointlgjapaneast-loadgen-func"
  #       FUNCTIONS_EMEA     = "aointlgfrancecen-loadgen-func,aointlggermanywe-loadgen-func"
  #     }
  # ]
  # These will then be added as app settings to the master functions
  function_names_per_geo = { for geo, regions in var.regional_functions_workers : "FUNCTIONS_${geo}" => join(",", [for region in regions : module.regional_functions[region].function_name]) }
}

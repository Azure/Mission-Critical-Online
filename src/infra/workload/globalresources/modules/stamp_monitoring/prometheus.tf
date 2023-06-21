locals {
  # regions where the creation of azure monitor workspaces is currently not supported - temporary fallback to westeurope
  unsupported_regions = [
    "australiaeast"
  ]
}

resource "azapi_resource" "prometheus" {
  type      = "microsoft.monitor/accounts@2021-06-03-preview"
  name      = "${local.prefix}-${local.location_short}-prometheus"
  parent_id = var.resource_group_id
  location  = contains(local.unsupported_regions, var.location) ? "westeurope" : var.location

  response_export_values = ["*"]
}
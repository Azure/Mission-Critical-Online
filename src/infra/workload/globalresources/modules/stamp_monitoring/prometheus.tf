resource "azapi_resource" "prometheus" {
  type      = "microsoft.monitor/accounts@2021-06-03-preview"
  name      = "${local.prefix}-${local.location_short}-prometheus"
  parent_id = var.resource_group_id
  location  = var.location

  response_export_values = ["*"]
}
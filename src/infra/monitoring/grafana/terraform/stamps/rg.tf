resource "azurerm_resource_group" "rg" {
  for_each = local.stamps
  name     = "${lower(var.prefix)}-grafana-${each.value}-rg"
  location = each.value
  tags = merge(local.default_tags,
    {
      "LastDeployedAt" = timestamp(),  # LastDeployedAt tag is only updated on the Resource Group, as otherwise every resource would be touched with every deployment
      "LastDeployedBy" = var.queued_by # typically contains the value of Build.QueuedBy (provided by Azure DevOps)}
    }
  )
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.65.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.7.0"
    }
  }
}

# Azure Resource Group used for all resources (per stamp)
resource "azurerm_resource_group" "stamp" {
  name     = "${var.prefix}-stamp-${var.location}-rg"
  location = var.location
  tags = merge(var.default_tags,
    {
      "LastDeployedAt" = timestamp(),  # LastDeployedAt tag is only updated on the Resource Group, as otherwise every resource would be touched with every deployment
      "LastDeployedBy" = var.queued_by # typically contains the value of Build.QueuedBy (provided by Azure DevOps)}
    }
  )
}
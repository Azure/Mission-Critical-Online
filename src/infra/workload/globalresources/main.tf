terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.2"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false # Hardcoded to false (for all environments) as expression do not work at the moment
    }
  }
}

resource "azurerm_resource_group" "global" {
  name     = "${local.prefix}-global-rg"
  location = local.location
  tags = merge(local.default_tags,
    {
      "LastDeployedAt" = timestamp(),  # LastDeployedAt tag is only updated on the Resource Group, as otherwise every resource would be touched with every deployment
      "LastDeployedBy" = var.queued_by # typically contains the value of Build.QueuedBy (provided by Azure DevOps)}
    }
  )
}


resource "azurerm_resource_group" "monitoring" {
  name     = "${local.prefix}-monitoring-rg"
  location = local.location
  tags = merge(local.default_tags,
    {
      "LastDeployedAt" = timestamp(),  # LastDeployedAt tag is only updated on the Resource Group, as otherwise every resource would be touched with every deployment
      "LastDeployedBy" = var.queued_by # typically contains the value of Build.QueuedBy (provided by Azure DevOps)}
    }
  )
}

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

    # Only in E2E can non-empty resource groups be deleted. This is not allowed in INT and PROD.
    resource_group {
      prevent_deletion_if_contains_resources = var.environment == "e2e" ? false : true
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

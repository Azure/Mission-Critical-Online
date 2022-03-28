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

    # Do not auto-generate some smart detection rules as this might lead to issues on destroy with non-TF managed resources
    application_insights {
      disable_generated_rule = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "deployment" {
  name     = "${local.prefix}-loadgenerator-rg"
  location = var.location
  tags     = merge(local.default_tags, { "LastDeployedAt" = timestamp() })
}

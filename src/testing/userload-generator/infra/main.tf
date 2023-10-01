terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.75.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "deployment" {
  name     = "${local.prefix}-loadgenerator-rg"
  location = var.location
  tags     = merge(local.default_tags, { "LastDeployedAt" = timestamp() })
}

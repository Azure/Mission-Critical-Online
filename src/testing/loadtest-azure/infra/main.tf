terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.65.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "deployment" {
  name     = "${local.prefix}-loadtest-rg"
  location = var.location
  tags     = merge(local.default_tags, { "LastDeployedAt" = timestamp() })
}

resource "azurerm_load_test" "loadtest" {
  name                = "${local.prefix}-azloadtest"
  location            = azurerm_resource_group.deployment.location
  resource_group_name = azurerm_resource_group.deployment.name

  tags = local.default_tags
}

output "azureLoadTestName" {
  value = azurerm_load_test.loadtest.name
}

output "azureLoadTestDataPlaneURI" {
  value = azurerm_load_test.loadtest.data_plane_uri
}

output "azureLoadResourceGroup" {
  value = azurerm_resource_group.deployment.name
}
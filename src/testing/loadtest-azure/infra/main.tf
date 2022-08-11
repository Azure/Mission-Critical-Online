terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.16.0"
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

resource "azurerm_load_test" "deployment" {
  name                = "${local.prefix}-azloadtest"
  resource_group_name = azurerm_resource_group.deployment.name
  location            = azurerm_resource_group.deployment.location

  tags = local.default_tags
}

output "azureLoadTestName" {
  value = azurerm_load_test.deployment.name
}

output "azureLoadResourceGroup" {
  value = azurerm_load_test.deployment.resource_group_name
}

output "azureLoadTestDataPlaneURI" {
  value = azurerm_load_test.deployment.dataplane_uri
}
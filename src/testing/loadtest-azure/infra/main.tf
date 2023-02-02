terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.41.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.3.0"
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

resource "azapi_resource" "azurerm_load_test" {
  type      = "Microsoft.LoadTestService/loadTests@2022-04-15-preview"
  name      = "${local.prefix}-azloadtest"
  parent_id = azurerm_resource_group.deployment.id

  location = azurerm_resource_group.deployment.location

  tags = local.default_tags

  response_export_values = ["properties.dataPlaneURI"]
}

output "azureLoadTestName" {
  value = azapi_resource.azurerm_load_test.name
}

output "azureLoadTestDataPlaneURI" {
  value = jsondecode(azapi_resource.azurerm_load_test.output).properties.dataPlaneURI
}

### Currently deployed via AzAPI ### 
#
# resource "azurerm_load_test" "deployment" {
#   name                = "${local.prefix}-azloadtest"
#   resource_group_name = azurerm_resource_group.deployment.name
#   location            = azurerm_resource_group.deployment.location

#   tags = local.default_tags
# }

# output "azureLoadTestName" {
#   value = azurerm_load_test.deployment.name
# }

# output "azureLoadTestDataPlaneURI" {
#   value = azurerm_load_test.deployment.dataplane_uri
# }

output "azureLoadResourceGroup" {
  value = azurerm_resource_group.deployment.name
}
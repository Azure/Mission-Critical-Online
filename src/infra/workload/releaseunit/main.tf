terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.63.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.5.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      # Allows the deletion of non-empty resource groups
      # This is required to delete rgs with stale resources left
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

# Random API key which needs to be identical between all stamps
resource "random_password" "api_key" {
  length  = 32
  special = false
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.97.1"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.12.1"
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

# Register the compute resource provider with the EncryptionAtHost feature (optional)
resource "azurerm_resource_provider_registration" "compute" {
  name = "Microsoft.Compute"

  dynamic "feature" {
    for_each = var.aks_enable_host_encryption ? [1] : []
    content {
      name       = "EncryptionAtHost"
      registered = true
    }
  }
}
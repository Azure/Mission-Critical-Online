terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.38.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.2.0"
    }
  }
}
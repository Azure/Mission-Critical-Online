terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.55.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.4.0"
    }
  }
}
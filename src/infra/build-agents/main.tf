terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.85.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "deployment" {
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.default_tags
}

# Data template cloud-init bootstrapping file used by the VMSS
data "local_file" "cloudinit" {
  filename = "${path.module}/cloudinit.conf"
}
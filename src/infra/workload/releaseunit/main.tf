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

# Random API key which needs to be identical between all stamps
resource "random_password" "api_key" {
  length  = 32
  special = false
}
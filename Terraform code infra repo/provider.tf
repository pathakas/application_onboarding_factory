provider "azurerm" {
  features {}
  subscription_id = ""
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.3"
    backend "azurerm" {
        resource_group_name  = "tfstate-rg"
        storage_account_name = "tfstatestorage"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
    }
}

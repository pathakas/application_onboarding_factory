terraform {

  cloud {

    organization = "devops-warriors"

    workspaces {
      name = "mf-platform-app-demo"
    }
  }
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.50.0"
    }
    # azurerm = {
    #   source  = "hashicorp/azurerm"
    #   version = "~> 3.0.2"
    # }
    # azuread = {
    #   source  = "hashicorp/azuread"
    #   version = "~> 2.34.1"
    # }
  }
  # required_version = ">= 1.1.0"
}
provider "github" {
  token = var.github_token != "" ? var.github_token : getenv("GITHUB_TOKEN")
  owner = "pathakas"
}

provider "tfe" {
  token        = var.tfe_token
  organization = "devops-warriors"
}
# provider "azurerm" {
#   features {}
#   subscription_id = var.subscription_id
#   client_id       = var.client_id
#   client_secret   = var.client_secret
#   tenant_id       = var.tenant_id
#   #skip_provider_registration = true
# }

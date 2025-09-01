terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.39"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
  backend "azurerm" { 
    resource_group_name = "rg_main"
    storage_account_name = "mainstrgacct"
    container_name = "maincontainer"
    key = "tf.tfstate"
    
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = "e614c005-fbcf-4e74-809b-f099ff6f5246"
}
# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "lfo" {
  source = "../../modules/automation"
  providers = {
    azurerm = azurerm
  }

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
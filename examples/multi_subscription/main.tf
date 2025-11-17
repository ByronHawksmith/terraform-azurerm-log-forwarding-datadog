terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# CRITICAL: All resource groups across subscriptions MUST use the same name
# The scaling task uses a single RESOURCE_GROUP environment variable for all subscriptions
locals {
  resource_group_name = var.resource_group_name
}

# Configure provider for the control plane subscription
# This is where the automation infrastructure will be deployed
provider "azurerm" {
  alias           = "control_plane"
  subscription_id = var.control_plane_subscription_id
  features {}
}

# Configure provider for the monitored subscription
# This is where the monitored resource group will be created
provider "azurerm" {
  alias           = "monitored"
  subscription_id = var.monitored_subscription_id
  features {}
}

# Deploy resource group in the monitored subscription
# This resource group will be monitored by the Datadog automation
module "monitored_resource_group" {
  source = "../../modules/automated-resource-group"

  providers = {
    azurerm = azurerm.monitored
  }

  resource_group_name = local.resource_group_name # CRITICAL: Same name as control plane
  location            = var.location
  tags                = var.tags
}

# Deploy the Datadog log forwarding automation in the control plane subscription
# This creates the control plane infrastructure that will manage log forwarding
module "automation" {
  source = "../../modules/automation"

  providers = {
    azurerm = azurerm.control_plane
  }

  resource_group_name = local.resource_group_name # CRITICAL: Same name as monitored
  location            = var.location
  tags                = var.tags

  # Pass the monitored resource group information to the automation module
  monitored_resource_groups = {
    (module.monitored_resource_group.subscription_id) = {
      subscription_id     = module.monitored_resource_group.subscription_id
      resource_group_name = module.monitored_resource_group.resource_group_name
    }
  }
}

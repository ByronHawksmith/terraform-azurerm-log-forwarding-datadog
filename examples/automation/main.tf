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

# Data source to get control plane subscription info
data "azurerm_subscription" "control_plane" {
  provider        = azurerm.control_plane
  subscription_id = var.control_plane_subscription_id
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

  # Datadog configuration
  datadog_api_key   = var.datadog_api_key
  datadog_site      = var.datadog_site
  datadog_telemetry = false

  # Resource discovery configuration
  resource_tag_filters = var.resource_tag_filters

  # Deployer configuration
  storage_account_url = var.storage_account_url
  image_registry      = var.image_registry
  deployer_image_tag  = var.deployer_image_tag

  # monitored_resource_groups will limit which subscriptions are monitored by the automation
  # here we pass the contol plane subscription in addition to the monitored subscription to collect logs from both
  monitored_resource_groups = {
    # Control plane subscription - where automation infrastructure lives
    (data.azurerm_subscription.control_plane.subscription_id) = {
      subscription_id     = data.azurerm_subscription.control_plane.subscription_id
      resource_group_name = local.resource_group_name
    }
    # Monitored subscription - the separate subscription with monitored resources
    (module.monitored_resource_group.subscription_id) = {
      subscription_id     = module.monitored_resource_group.subscription_id
      resource_group_name = module.monitored_resource_group.resource_group_name
    }
  }
}

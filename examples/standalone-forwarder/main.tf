terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "0b62a232-b8db-4380-9da6-640f7272ed6d"
}

# ==========================================
# Resource Group
# ==========================================
# This example assumes you have an existing resource group.
# If you need to create one, uncomment the resource below:
#
# resource "azurerm_resource_group" "example" {
#   name     = "rg-datadog-forwarder-example"
#   location = var.location
# }

# ==========================================
# Datadog Log Forwarder Module
# ==========================================

module "forwarder" {
  source = "../../modules/forwarder"

  # Required: Resource Group and Location
  resource_group_name = var.resource_group_name
  location            = var.location

  # Required: Unique Storage Account Name
  # Note: Storage account names must be globally unique across Azure
  storage_account_name = var.storage_account_name

  # Required: Datadog Configuration
  datadog_api_key = var.datadog_api_key
  datadog_site    = var.datadog_site

  # Optional: Container App Job Resource Configuration
  # Uncomment to customize CPU and memory allocation
  # forwarder_cpu    = 1.0  # Reduce CPU to 1 core for lower volume workloads
  # forwarder_memory = "2Gi" # Reduce memory to 2Gi for lower volume workloads

  # Optional: Storage Configuration
  # Uncomment to customize storage settings
  # storage_account_sku           = "Standard_LRS"  # Most cost-effective for log forwarding
  # storage_account_retention_days = 1              # Minimum retention for cost optimization
  # storage_access_tier           = "Hot"           # Hot tier for frequent access

  # Optional: Schedule Configuration
  # Uncomment to customize how often the forwarder runs
  # schedule_expression = "*/5 * * * *"  # Run every 5 minutes instead of every minute

  # Optional: Execution Configuration
  # Uncomment to customize job execution behavior
  # replica_timeout_in_seconds = 1800  # Maximum 30 minutes per execution
  # replica_retry_limit        = 1     # Retry once on failure

  # Optional: Resource Naming
  # Uncomment to customize resource names
  # environment_name = "my-datadog-forwarder-env"
  # job_name         = "my-datadog-forwarder"

  # Optional: Tags
  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
    Purpose     = "datadog-log-forwarding"
  }
}

# ==========================================
# Outputs
# ==========================================

output "storage_account_name" {
  description = "Name of the created storage account"
  value       = module.forwarder.storage_account_name
}

output "storage_account_id" {
  description = "ID of the created storage account"
  value       = module.forwarder.storage_account_id
}

output "container_app_job_name" {
  description = "Name of the container app job"
  value       = module.forwarder.container_app_job_name
}

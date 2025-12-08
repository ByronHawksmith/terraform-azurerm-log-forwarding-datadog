terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ==========================================
# Data Sources
# ==========================================

data "azurerm_resource_group" "current" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

# ==========================================
# Local Values
# ==========================================

locals {
  storage_connection_string = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.forwarder_storage.name};EndpointSuffix=core.windows.net;AccountKey=${azurerm_storage_account.forwarder_storage.primary_access_key}"
}

# ==========================================
# Storage Account
# ==========================================

resource "azurerm_storage_account" "forwarder_storage" {
  name                            = var.storage_account_name
  resource_group_name             = data.azurerm_resource_group.current.name
  location                        = var.location
  account_tier                    = split("_", var.storage_account_sku)[0]
  account_replication_type        = split("_", var.storage_account_sku)[1]
  account_kind                    = "StorageV2"
  access_tier                     = var.storage_access_tier
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  tags = var.tags
}

# ==========================================
# Storage Account Management Policy
# ==========================================

resource "azurerm_storage_management_policy" "forwarder_lifecycle" {
  storage_account_id = azurerm_storage_account.forwarder_storage.id

  rule {
    name    = "delete-old-blobs"
    enabled = true

    filters {
      blob_types = ["blockBlob", "appendBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.storage_account_retention_days
      }
      snapshot {
        delete_after_days_since_creation_greater_than = var.storage_account_retention_days
      }
    }
  }
}

# ==========================================
# Container App Environment
# ==========================================

resource "azurerm_container_app_environment" "forwarder_env" {
  name                = var.environment_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.current.name

  tags = var.tags
}

# ==========================================
# Container App Job
# ==========================================

resource "azurerm_container_app_job" "forwarder" {
  name                         = var.job_name
  location                     = var.location
  resource_group_name          = data.azurerm_resource_group.current.name
  container_app_environment_id = azurerm_container_app_environment.forwarder_env.id

  replica_timeout_in_seconds = var.replica_timeout_in_seconds
  replica_retry_limit        = var.replica_retry_limit

  schedule_trigger_config {
    cron_expression          = var.schedule_expression
    parallelism              = 1
    replica_completion_count = 1
  }

  template {
    container {
      name   = "datadog-forwarder"
      image  = var.forwarder_image
      cpu    = var.forwarder_cpu
      memory = var.forwarder_memory

      env {
        name        = "AzureWebJobsStorage"
        secret_name = "storage-connection-string"
      }
      env {
        name        = "DD_API_KEY"
        secret_name = "dd-api-key"
      }
      env {
        name  = "DD_SITE"
        value = var.datadog_site
      }
      env {
        name  = "CONTROL_PLANE_ID"
        value = "none"
      }
      env {
        name  = "CONFIG_ID"
        value = "standalone-forwarder"
      }
    }
  }

  secret {
    name  = "storage-connection-string"
    value = local.storage_connection_string
  }

  secret {
    name  = "dd-api-key"
    value = var.datadog_api_key
  }

  tags = var.tags
}

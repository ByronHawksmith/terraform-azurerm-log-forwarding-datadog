# Unless explicitly stated otherwise all files in this repository are licensed under the Apache-2 License.

# This product includes software developed at Datadog (https://www.datadoghq.com/) Copyright 2025 Datadog, Inc.

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Locals for resource naming and configuration
locals {
  # Use provided control_plane_id or generate a random one
  control_plane_id = var.control_plane_id != null && var.control_plane_id != "" ? var.control_plane_id : random_string.control_plane_id[0].result

  # Extract unique subscription IDs from monitored resource groups
  monitored_subscriptions = distinct([
    for rg in values(var.monitored_resource_groups) : rg.subscription_id
  ])

  # Resource naming convention
  resource_names = {
    storage_account          = "lfostorage${local.control_plane_id}"
    app_service_plan         = "control-plane-asp-${local.control_plane_id}"
    resources_task           = "resources-task-${local.control_plane_id}"
    scaling_task             = "scaling-task-${local.control_plane_id}"
    diagnostic_settings_task = "diagnostic-settings-task-${local.control_plane_id}"
    file_share               = "resources-task-${local.control_plane_id}"
    cache_container          = "control-plane-cache"
    container_app_env        = "dd-log-forwarder-env-${local.control_plane_id}"
    deployer_task            = "deployer-task-${local.control_plane_id}"
  }

  # Container images
  deployer_image_url = "${var.image_registry}/deployer:${var.deployer_image_tag}"

  # Storage connection string for function apps
  storage_connection_string = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.control_plane.name};EndpointSuffix=${azurerm_storage_account.control_plane.primary_blob_endpoint != "" ? "core.windows.net" : ""};AccountKey=${azurerm_storage_account.control_plane.primary_access_key}"

  # Common app settings for all function apps
  # Note: AzureWebJobsStorage and FUNCTIONS_EXTENSION_VERSION are auto-managed by Azure
  # when using storage_account_name/storage_account_access_key - do not duplicate here
  common_app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = local.storage_connection_string
    FUNCTIONS_WORKER_RUNTIME                 = "python"
    AzureWebJobsFeatureFlags                 = "EnableWorkerIndexing"
    FUNCTIONS_WORKER_PROCESS_COUNT           = "1"
    CONTROL_PLANE_ID                         = local.control_plane_id
    LOG_LEVEL                                = var.log_level
    DD_API_KEY                               = var.datadog_api_key
    DD_SITE                                  = var.datadog_site
    DD_TELEMETRY                             = tostring(var.datadog_telemetry)
    AZURE_CLIENT_ID                          = ""
    AZURE_TENANT_ID                          = ""
    AZURE_SUBSCRIPTION_ID                    = data.azurerm_subscription.current.subscription_id
  }
}

# Generate random control plane ID if not provided
resource "random_string" "control_plane_id" {
  count   = var.control_plane_id == null || var.control_plane_id == "" ? 1 : 0
  length  = 12
  special = false
  upper   = false
  numeric = true
  lower   = true
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Storage Account for Control Plane
# Used by all function apps for content, cache, and coordination
resource "azurerm_storage_account" "control_plane" {
  name                            = local.resource_names.storage_account
  resource_group_name             = azurerm_resource_group.resource_group.name
  location                        = azurerm_resource_group.resource_group.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_replication_type
  account_kind                    = "StorageV2"
  access_tier                     = "Hot"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = var.private_networking_enabled ? false : true

  dynamic "network_rules" {
    for_each = var.private_networking_enabled ? [1] : []
    content {
      default_action = "Deny"
      bypass         = ["AzureServices"]
    }
  }

  blob_properties {
    change_feed_enabled = false
    versioning_enabled  = false
  }

  tags = var.tags
}

# File share for function app content
resource "azurerm_storage_share" "function_content" {
  name               = local.resource_names.file_share
  storage_account_id = azurerm_storage_account.control_plane.id
  quota              = 50

  depends_on = [azurerm_storage_account.control_plane]
}

# Blob container for control plane cache
resource "azurerm_storage_container" "cache" {
  name                  = local.resource_names.cache_container
  storage_account_id    = azurerm_storage_account.control_plane.id
  container_access_type = "private"

  depends_on = [azurerm_storage_account.control_plane]
}

# Lifecycle management policy to clean up old cache and logs
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.control_plane.id

  rule {
    name    = "delete-old-cache-blobs"
    enabled = true

    filters {
      prefix_match = ["${local.resource_names.cache_container}/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.cache_retention_days
      }
    }
  }

  rule {
    name    = "delete-old-function-logs"
    enabled = true

    filters {
      prefix_match = ["azure-webjobs-hosts/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.cache_retention_days
      }
    }
  }
}

# App Service Plan for Control Plane Function Apps
# Y1 (Consumption) plan for cost-effective serverless execution
resource "azurerm_service_plan" "control_plane" {
  name                = local.resource_names.app_service_plan
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = var.tags
}

# Resources Task Function App
# Discovers and tracks all log-generating Azure resources across monitored subscriptions
resource "azurerm_linux_function_app" "resources_task" {
  name                = local.resource_names.resources_task
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  service_plan_id     = azurerm_service_plan.control_plane.id

  storage_account_name       = azurerm_storage_account.control_plane.name
  storage_account_access_key = azurerm_storage_account.control_plane.primary_access_key

  https_only = true

  public_network_access_enabled = var.private_networking_enabled ? false : true

  site_config {
    application_stack {
      python_version = "3.11"
    }

    ftps_state                             = "Disabled"
    use_32_bit_worker                      = false
    application_insights_connection_string = null
    vnet_route_all_enabled                 = var.private_networking_enabled ? true : false
  }

  virtual_network_subnet_id = var.private_networking_enabled ? var.vnet_integration_subnet_id : null

  app_settings = merge(
    local.common_app_settings,
    {
      WEBSITE_CONTENTSHARE    = local.resource_names.resources_task
      MONITORED_SUBSCRIPTIONS = jsonencode(local.monitored_subscriptions)
      RESOURCE_TAG_FILTERS    = var.resource_tag_filters
    }
  )

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["AzureWebJobsStorage"],
      app_settings["FUNCTIONS_EXTENSION_VERSION"],
    ]
  }

  depends_on = [
    azurerm_storage_share.function_content,
    azurerm_storage_container.cache
  ]
}

# Scaling Task Function App
# Intelligently manages log forwarder lifecycle - creates, scales, and deletes forwarders
resource "azurerm_linux_function_app" "scaling_task" {
  name                = local.resource_names.scaling_task
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  service_plan_id     = azurerm_service_plan.control_plane.id

  storage_account_name       = azurerm_storage_account.control_plane.name
  storage_account_access_key = azurerm_storage_account.control_plane.primary_access_key

  https_only = true

  public_network_access_enabled = var.private_networking_enabled ? false : true

  site_config {
    application_stack {
      python_version = "3.11"
    }

    ftps_state                             = "Disabled"
    use_32_bit_worker                      = false
    application_insights_connection_string = null
    vnet_route_all_enabled                 = var.private_networking_enabled ? true : false
  }

  virtual_network_subnet_id = var.private_networking_enabled ? var.vnet_integration_subnet_id : null

  app_settings = merge(
    local.common_app_settings,
    {
      WEBSITE_CONTENTSHARE = local.resource_names.scaling_task
      RESOURCE_GROUP       = var.resource_group_name
      FORWARDER_IMAGE      = var.forwarder_image
      CONTROL_PLANE_REGION = var.location
      PII_SCRUBBER_RULES   = var.pii_scrubber_rules
      SCALING_PERCENTAGE   = "0.8"
    }
  )

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["AzureWebJobsStorage"],
      app_settings["FUNCTIONS_EXTENSION_VERSION"],
    ]
  }

  depends_on = [
    azurerm_storage_share.function_content,
    azurerm_storage_container.cache
  ]
}

# Diagnostic Settings Task Function App
# Automatically configures Azure Diagnostic Settings on discovered resources
resource "azurerm_linux_function_app" "diagnostic_settings_task" {
  name                = local.resource_names.diagnostic_settings_task
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  service_plan_id     = azurerm_service_plan.control_plane.id

  storage_account_name       = azurerm_storage_account.control_plane.name
  storage_account_access_key = azurerm_storage_account.control_plane.primary_access_key

  https_only = true

  public_network_access_enabled = var.private_networking_enabled ? false : true

  site_config {
    application_stack {
      python_version = "3.11"
    }

    ftps_state                             = "Disabled"
    use_32_bit_worker                      = false
    application_insights_connection_string = null
    vnet_route_all_enabled                 = var.private_networking_enabled ? true : false
  }

  virtual_network_subnet_id = var.private_networking_enabled ? var.vnet_integration_subnet_id : null

  app_settings = merge(
    local.common_app_settings,
    {
      WEBSITE_CONTENTSHARE = local.resource_names.diagnostic_settings_task
      RESOURCE_GROUP       = var.resource_group_name
    }
  )

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      app_settings["AzureWebJobsStorage"],
      app_settings["FUNCTIONS_EXTENSION_VERSION"],
    ]
  }

  depends_on = [
    azurerm_storage_share.function_content,
    azurerm_storage_container.cache
  ]
}

# =====================================================
# Deployer Container App Infrastructure
# =====================================================

# Container Apps Environment for Deployer Task
# Provides the execution environment for the deployer container app job
resource "azurerm_container_app_environment" "deployer_env" {
  name                = local.resource_names.container_app_env
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  internal_load_balancer_enabled = var.private_networking_enabled
  infrastructure_subnet_id       = var.private_networking_enabled ? var.vnet_integration_subnet_id : null

  tags = var.tags
}

# Container App Job for Deployer Task
# Automatically updates control plane function apps when new versions are available
# Runs on a schedule to check for updates from the public storage account
resource "azurerm_container_app_job" "deployer_task" {
  name                         = local.resource_names.deployer_task
  location                     = azurerm_resource_group.resource_group.location
  resource_group_name          = azurerm_resource_group.resource_group.name
  container_app_environment_id = azurerm_container_app_environment.deployer_env.id

  replica_timeout_in_seconds = 1800 # 30 minutes
  replica_retry_limit        = 1

  # Schedule trigger configuration
  schedule_trigger_config {
    cron_expression          = var.deployer_schedule
    parallelism              = 1
    replica_completion_count = 1
  }

  # Container template
  template {
    container {
      name   = local.resource_names.deployer_task
      image  = local.deployer_image_url
      cpu    = 0.5
      memory = "1Gi"

      # Environment variables for deployer task
      env {
        name        = "AzureWebJobsStorage"
        secret_name = "connection-string"
      }

      env {
        name  = "SUBSCRIPTION_ID"
        value = data.azurerm_subscription.current.subscription_id
      }

      env {
        name  = "RESOURCE_GROUP"
        value = var.resource_group_name
      }

      env {
        name  = "CONTROL_PLANE_ID"
        value = local.control_plane_id
      }

      env {
        name  = "CONTROL_PLANE_REGION"
        value = var.location
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
        name  = "DD_TELEMETRY"
        value = tostring(var.datadog_telemetry)
      }

      env {
        name  = "STORAGE_ACCOUNT_URL"
        value = var.storage_account_url
      }

      env {
        name  = "LOG_LEVEL"
        value = var.log_level
      }
    }
  }

  # Secrets for deployer task
  secret {
    name  = "connection-string"
    value = local.storage_connection_string
  }

  secret {
    name  = "dd-api-key"
    value = var.datadog_api_key
  }

  # System-assigned managed identity for authentication
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_container_app_environment.deployer_env,
    azurerm_storage_account.control_plane
  ]
}

# =====================================================
# Role Assignments for Function App Managed Identities
# =====================================================

# Resources Task: Monitoring Reader on each monitored subscription
# Allows read-only access to discover resources
resource "azurerm_role_assignment" "resources_task_monitoring_reader" {
  for_each = toset(local.monitored_subscriptions)

  scope                            = "/subscriptions/${each.value}"
  role_definition_name             = "Monitoring Reader"
  principal_id                     = azurerm_linux_function_app.resources_task.identity[0].principal_id
  description                      = "ddlfo${local.control_plane_id}"
  skip_service_principal_aad_check = true

  depends_on = [azurerm_linux_function_app.resources_task]
}

# Scaling Task: Contributor on each monitored resource group
# Allows creation and management of forwarder resources
resource "azurerm_role_assignment" "scaling_task_contributor" {
  for_each = var.monitored_resource_groups

  scope                            = "/subscriptions/${each.value.subscription_id}/resourceGroups/${each.value.resource_group_name}"
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_linux_function_app.scaling_task.identity[0].principal_id
  description                      = "ddlfo${local.control_plane_id}"
  skip_service_principal_aad_check = true

  depends_on = [azurerm_linux_function_app.scaling_task]
}

# Diagnostic Settings Task: Monitoring Contributor on each monitored subscription
# Allows creation and modification of diagnostic settings
resource "azurerm_role_assignment" "diagnostic_settings_task_monitoring_contributor" {
  for_each = toset(local.monitored_subscriptions)

  scope                            = "/subscriptions/${each.value}"
  role_definition_name             = "Monitoring Contributor"
  principal_id                     = azurerm_linux_function_app.diagnostic_settings_task.identity[0].principal_id
  description                      = "ddlfo${local.control_plane_id}"
  skip_service_principal_aad_check = true

  depends_on = [azurerm_linux_function_app.diagnostic_settings_task]
}

# Diagnostic Settings Task: Reader and Data Access on each monitored resource group
# Allows read access to storage accounts in monitored resource groups
resource "azurerm_role_assignment" "diagnostic_settings_task_reader_data_access" {
  for_each = var.monitored_resource_groups

  scope                            = "/subscriptions/${each.value.subscription_id}/resourceGroups/${each.value.resource_group_name}"
  role_definition_name             = "Reader and Data Access"
  principal_id                     = azurerm_linux_function_app.diagnostic_settings_task.identity[0].principal_id
  description                      = "ddlfo${local.control_plane_id}"
  skip_service_principal_aad_check = true

  depends_on = [azurerm_linux_function_app.diagnostic_settings_task]
}

# =====================================================
# Role Assignments for Deployer Task Managed Identity
# =====================================================

# Deployer Task: Website Contributor on automation resource group
# Allows the deployer to update function apps via the SCM endpoint
resource "azurerm_role_assignment" "deployer_task_website_contributor" {
  scope                            = azurerm_resource_group.resource_group.id
  role_definition_name             = "Website Contributor"
  principal_id                     = azurerm_container_app_job.deployer_task.identity[0].principal_id
  description                      = "ddlfo${local.control_plane_id}"
  skip_service_principal_aad_check = true

  depends_on = [azurerm_container_app_job.deployer_task]
}

# Deployer Task: Monitoring Contributor on each monitored subscription
# Required for the initial run to configure diagnostic settings
resource "azurerm_role_assignment" "deployer_task_monitoring_contributor" {
  for_each = toset(local.monitored_subscriptions)

  scope                            = "/subscriptions/${each.value}"
  role_definition_name             = "Monitoring Contributor"
  principal_id                     = azurerm_container_app_job.deployer_task.identity[0].principal_id
  description                      = "ddlfo${local.control_plane_id}"
  skip_service_principal_aad_check = true

  depends_on = [azurerm_container_app_job.deployer_task]
}

# Deployer Task: Contributor on each monitored resource group
# Allows the initial run to create forwarder resources
resource "azurerm_role_assignment" "deployer_task_contributor" {
  for_each = var.monitored_resource_groups

  scope                            = "/subscriptions/${each.value.subscription_id}/resourceGroups/${each.value.resource_group_name}"
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_container_app_job.deployer_task.identity[0].principal_id
  description                      = "ddlfo${local.control_plane_id}"
  skip_service_principal_aad_check = true

  depends_on = [azurerm_container_app_job.deployer_task]
}

# Unless explicitly stated otherwise all files in this repository are licensed under the Apache-2 License.

# This product includes software developed at Datadog (https://www.datadoghq.com/) Copyright 2025 Datadog, Inc.

variable "control_plane_subscription_id" {
  description = "Azure subscription ID where the control plane automation infrastructure will be deployed"
  type        = string
}

variable "monitored_subscription_id" {
  description = "Azure subscription ID that will be monitored by the Datadog log forwarding automation"
  type        = string
}

variable "resource_group_name" {
  description = <<-EOT
    Name of the resource group to use across ALL subscriptions.

    CRITICAL: This same name will be used for the resource group in BOTH the control plane
    subscription and the monitored subscription. The scaling task uses a single RESOURCE_GROUP
    environment variable to manage resources across all subscriptions, so all resource groups
    must have identical names.

    The automation module includes validation that will fail if monitored resource groups
    don't match this name.
  EOT
  type        = string
  default     = "rg-datadog-log-forwarding"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    environment = "example"
    managed_by  = "terraform"
  }
}

variable "datadog_api_key" {
  description = "Datadog API key for sending logs and metrics"
  type        = string
  sensitive   = true
}

variable "datadog_site" {
  description = "Datadog site to send logs to (e.g., datadoghq.com, datadoghq.eu)"
  type        = string
  default     = "datadoghq.com"
}

variable "resource_tag_filters" {
  description = "Comma-separated list of tag filters for resource discovery"
  type        = string
  default     = ""
}

variable "storage_account_url" {
  description = <<-EOT
    URL of the public storage account containing function app deployment packages.
    The deployer task downloads function app code from this storage account.
    If not specified, defaults to https://ddazurelfo.blob.core.windows.net

    For development environments, you can override this to point to your own storage
    account created by https://github.com/DataDog/azure-log-forwarding-orchestration/blob/main/scripts/deploy_personal_env.py

    Example: "https://lfoyourusername.blob.core.windows.net"
  EOT
  type        = string
  default     = "https://ddazurelfo.blob.core.windows.net"
}

variable "image_registry" {
  description = <<-EOT
    Container registry for the deployer container image.
    If not specified, defaults to datadoghq.azurecr.io

    For development environments, you can override this to point to your own
    container registry created by https://github.com/DataDog/azure-log-forwarding-orchestration/blob/main/scripts/deploy_personal_env.py

    Example: "lfoyourusername.azurecr.io"
  EOT
  type        = string
  default     = "datadoghq.azurecr.io"
}

variable "deployer_image_tag" {
  description = "Tag for the deployer container image"
  type        = string
  default     = "latest"
}

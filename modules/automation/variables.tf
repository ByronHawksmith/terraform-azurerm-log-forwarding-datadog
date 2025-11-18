variable "resource_group_name" {
  description = <<-EOT
    Name of the resource group where control plane resources will be created.

    CRITICAL: When using multi-subscription deployment, all monitored subscriptions must have
    resource groups with this EXACT SAME NAME. The scaling task uses a single RESOURCE_GROUP
    environment variable to manage resources across all subscriptions. This ensures consistent
    resource organization and simplified operations.
  EOT
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "monitored_resource_groups" {
  description = <<-EOT
    Map of subscription IDs to resource group information for monitored subscriptions.
    This is reserved for future use to grant function app permissions on resource groups
    in other subscriptions. The function app will be able to create resources in these
    resource groups using its managed identity.

    CRITICAL: All resource_group_name values MUST match var.resource_group_name exactly.
    The scaling task uses a single RESOURCE_GROUP environment variable across all subscriptions.
    You must ensure all monitored resource groups use the same name as the control plane resource group.

    Example:
    {
      "00000000-0000-0000-0000-000000000001" = {
        subscription_id     = "00000000-0000-0000-0000-000000000001"
        resource_group_name = "rg-datadog-log-forwarding"  # Must match var.resource_group_name
      }
    }

    To ensure consistency, use a local variable:
    locals {
      resource_group_name = "rg-datadog-log-forwarding"
    }

    module "automation" {
      resource_group_name = local.resource_group_name
      monitored_resource_groups = {
        "sub-id" = {
          subscription_id     = "sub-id"
          resource_group_name = local.resource_group_name  # Same name!
        }
      }
    }
  EOT
  type = map(object({
    subscription_id     = string
    resource_group_name = string
  }))
  default = {}
}

# Control Plane ID Configuration

variable "control_plane_id" {
  description = <<-EOT
    Optional control plane identifier. If not provided, a random 12-character alphanumeric
    string will be generated. This ID is used in resource naming to ensure uniqueness.

    Requirements:
    - Must be lowercase alphanumeric only (a-z, 0-9)
    - Must be 12 characters or less
    - Will be used in storage account name (24 char limit: "lfostorage" + control_plane_id)

    Example: "abc123def456"
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.control_plane_id == null || can(regex("^[a-z0-9]{1,12}$", var.control_plane_id))
    error_message = "control_plane_id must be lowercase alphanumeric and 12 characters or less."
  }
}

# Storage Configuration

variable "storage_replication_type" {
  description = "Storage account replication type for control plane storage"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "ZRS", "GZRS"], var.storage_replication_type)
    error_message = "storage_replication_type must be one of: LRS, GRS, ZRS, GZRS."
  }
}

variable "cache_retention_days" {
  description = "Number of days to retain cache blobs before automatic deletion"
  type        = number
  default     = 7

  validation {
    condition     = var.cache_retention_days >= 1 && var.cache_retention_days <= 365
    error_message = "cache_retention_days must be between 1 and 365 days."
  }
}

# Datadog Configuration

variable "datadog_api_key" {
  description = "Datadog API key for sending logs and metrics"
  type        = string
  sensitive   = true
}

variable "datadog_site" {
  description = <<-EOT
    Datadog site to send logs to. Options:
    - datadoghq.com (US1)
    - us3.datadoghq.com (US3)
    - us5.datadoghq.com (US5)
    - datadoghq.eu (EU1)
    - ap1.datadoghq.com (AP1)
    - ap2.datadoghq.com (AP2)
    - ddog-gov.com (US1-FED)
  EOT
  type        = string
  default     = "datadoghq.com"

  validation {
    condition = contains([
      "datadoghq.com",
      "us3.datadoghq.com",
      "us5.datadoghq.com",
      "datadoghq.eu",
      "ap1.datadoghq.com",
      "ap2.datadoghq.com",
      "ddog-gov.com"
    ], var.datadog_site)
    error_message = "datadog_site must be one of: datadoghq.com, us3.datadoghq.com, us5.datadoghq.com, datadoghq.eu, ap1.datadoghq.com, ap2.datadoghq.com, ddog-gov.com."
  }
}

variable "datadog_telemetry" {
  description = "Enable Datadog telemetry for control plane function apps"
  type        = bool
  default     = false
}

# Function App Configuration

variable "log_level" {
  description = "Logging level for control plane function apps"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.log_level)
    error_message = "log_level must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL."
  }
}

variable "resource_tag_filters" {
  description = <<-EOT
    Comma-separated list of tag filters for resource discovery.
    Use '!' prefix to exclude resources with specific tags.

    Examples:
    - "env:prod,team:platform" - Include resources with these tags
    - "!env:dev" - Exclude dev environment resources
    - "env:prod,!temporary:true" - Include prod but exclude temporary resources
  EOT
  type        = string
  default     = ""
}

variable "forwarder_image" {
  description = "Container image for log forwarder jobs"
  type        = string
  default     = "datadoghq.azurecr.io/forwarder:latest"
}

variable "pii_scrubber_rules" {
  description = <<-EOT
    YAML-formatted PII scrubbing rules for log redaction.
    Applied to logs before forwarding to Datadog.

    Example:
    rules:
      - name: "Redact SSN"
        pattern: '\d{3}-\d{2}-\d{4}'
        replacement: '[REDACTED-SSN]'
  EOT
  type        = string
  default     = ""
}

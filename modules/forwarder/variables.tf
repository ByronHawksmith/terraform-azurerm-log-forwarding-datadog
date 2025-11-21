# ==========================================
# Resource Group and Location
# ==========================================

variable "resource_group_name" {
  description = <<-EOT
    Name of the resource group where resources will be created.
    This resource group must already exist.
  EOT
  type        = string
}

variable "location" {
  description = <<-EOT
    Azure region where resources will be created.
    Example: "East US", "West Europe", "Southeast Asia"
  EOT
  type        = string
  default     = "East US"
}

# ==========================================
# Naming
# ==========================================

variable "environment_name" {
  description = <<-EOT
    Name of the Container App Managed Environment for the Forwarder.
    Must be between 2 and 60 characters long.
  EOT
  type        = string
  default     = "datadog-log-forwarder-env"

  validation {
    condition     = length(var.environment_name) >= 2 && length(var.environment_name) <= 60
    error_message = "Environment name must be between 2 and 60 characters long."
  }
}

variable "job_name" {
  description = <<-EOT
    Name of the Forwarder Container App Job.
    Must be between 1 and 260 characters long.
  EOT
  type        = string
  default     = "datadog-log-forwarder"

  validation {
    condition     = length(var.job_name) >= 1 && length(var.job_name) <= 260
    error_message = "Job name must be between 1 and 260 characters long."
  }
}

variable "storage_account_name" {
  description = <<-EOT
    Name of the Log Storage Account.
    Must be between 3 and 24 characters long.
    Must be lowercase letters and numbers only.
    Must be globally unique across Azure.
  EOT
  type        = string
  default     = "datadoglogstorage"

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "Storage account name must be between 3 and 24 characters long."
  }

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.storage_account_name))
    error_message = "Storage account name must contain only lowercase letters and numbers."
  }
}

# ==========================================
# Container App Job Configuration
# ==========================================

variable "forwarder_image" {
  description = <<-EOT
    Container image for the forwarder.
    Example: "datadoghq.azurecr.io/forwarder:latest"
  EOT
  type        = string
  default     = "datadoghq.azurecr.io/forwarder:latest"
}

variable "forwarder_cpu" {
  description = <<-EOT
    CPU allocation for the forwarder container in cores.
    Valid values: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0
    Note: Consumption plan environments are limited to 2.0 CPU maximum.
  EOT
  type        = number
  default     = 2

  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.forwarder_cpu)
    error_message = "CPU must be one of: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0"
  }
}

variable "forwarder_memory" {
  description = <<-EOT
    Memory allocation for the forwarder container.
    Must be in the format of a number followed by 'Gi' (e.g., "0.5Gi", "1Gi", "2Gi", "4Gi").
    Note: Consumption plan environments are limited to 4Gi maximum.
  EOT
  type        = string
  default     = "4Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.forwarder_memory))
    error_message = "Memory must be in the format of a number followed by 'Gi' (e.g., '0.5Gi', '1Gi', '4Gi')."
  }
}

variable "replica_timeout_in_seconds" {
  description = <<-EOT
    Maximum number of seconds a replica is allowed to run.
    Must be between 60 and 1800 seconds (1 minute to 30 minutes).
    This timeout determines how long the forwarder job can run before being terminated.
  EOT
  type        = number
  default     = 1800

  validation {
    condition     = var.replica_timeout_in_seconds >= 60 && var.replica_timeout_in_seconds <= 1800
    error_message = "Replica timeout must be between 60 and 1800 seconds (1 minute to 30 minutes)."
  }
}

variable "replica_retry_limit" {
  description = <<-EOT
    Number of times to retry a failed replica.
    Must be between 0 and 10.
    A value of 0 means no retries, 1 means retry once, etc.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.replica_retry_limit >= 0 && var.replica_retry_limit <= 10
    error_message = "Replica retry limit must be between 0 and 10."
  }
}

variable "schedule_expression" {
  description = <<-EOT
    Cron expression for the forwarder job schedule.
    Uses standard cron format (minute hour day month weekday).
    Examples:
      - "* * * * *" (every minute)
      - "*/5 * * * *" (every 5 minutes)
      - "0 * * * *" (every hour)
  EOT
  type        = string
  default     = "* * * * *"
}

# ==========================================
# Storage Account Configuration
# ==========================================

variable "storage_account_sku" {
  description = <<-EOT
    The SKU of the storage account.
    Format: {Tier}_{Replication}
    - Premium tier supports LRS and ZRS only
    - Standard tier supports LRS, GRS, GZRS, and ZRS
    For log forwarding, Standard_LRS is typically sufficient and most cost-effective.
  EOT
  type        = string
  default     = "Standard_LRS"

  validation {
    condition = contains([
      "Premium_LRS",
      "Premium_ZRS",
      "Standard_GRS",
      "Standard_GZRS",
      "Standard_LRS",
      "Standard_ZRS"
    ], var.storage_account_sku)
    error_message = "Storage account SKU must be one of: Premium_LRS, Premium_ZRS, Standard_GRS, Standard_GZRS, Standard_LRS, Standard_ZRS."
  }
}

variable "storage_account_retention_days" {
  description = <<-EOT
    The number of days to retain logs in the storage account before automatic deletion.
    Must be at least 1 day.
    Lower values reduce storage costs but provide less time to recover from issues.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.storage_account_retention_days >= 1
    error_message = "Storage account retention days must be at least 1."
  }
}

variable "storage_access_tier" {
  description = <<-EOT
    Access tier for the storage account.
    - "Hot": Optimized for frequent access (higher storage cost, lower access cost)
    - "Cool": Optimized for infrequent access (lower storage cost, higher access cost)
    For log forwarding with short retention periods, "Hot" is typically appropriate.
  EOT
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.storage_access_tier)
    error_message = "Storage access tier must be either 'Hot' or 'Cool'."
  }
}

# ==========================================
# Datadog Configuration
# ==========================================

variable "datadog_api_key" {
  description = <<-EOT
    Datadog API Key for authentication.
    Must be exactly 32 characters long.
    This is stored as a secret in the Container App Job.
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.datadog_api_key) == 32
    error_message = "Datadog API key must be exactly 32 characters long."
  }
}

variable "datadog_site" {
  description = <<-EOT
    Datadog Site to send logs to.
    Must be one of the official Datadog sites.
  EOT
  type        = string
  default     = "datadoghq.com"

  validation {
    condition = contains([
      "datadoghq.com",
      "datadoghq.eu",
      "ap1.datadoghq.com",
      "ap2.datadoghq.com",
      "us3.datadoghq.com",
      "us5.datadoghq.com",
      "ddog-gov.com",
      "datad0g.com",
    ], var.datadog_site)
    error_message = "Datadog site must be one of: datadoghq.com, datadoghq.eu, ap1.datadoghq.com, ap2.datadoghq.com, us3.datadoghq.com, us5.datadoghq.com, ddog-gov.com, datad0g.com."
  }
}

# ==========================================
# General
# ==========================================

variable "tags" {
  description = <<-EOT
    Tags to apply to all resources.
    Example: { Environment = "production", ManagedBy = "terraform" }
  EOT
  type        = map(string)
  default     = {}
}

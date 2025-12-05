variable "resource_group_name" {
  description = "Name of the existing resource group where resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, 3-24 lowercase alphanumeric characters)"
  type        = string
}

variable "datadog_api_key" {
  description = "Datadog API Key (32 characters)"
  type        = string
  sensitive   = true
}

variable "datadog_site" {
  description = "Datadog Site (e.g., datadoghq.com, datadoghq.eu)"
  type        = string
  default     = "datadoghq.com"
}

variable "resource_group_name" {
  description = "Name of the resource group where resources will be created"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID to use for the provider (defaults to first monitored subscription)"
  type        = string
  default     = null
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

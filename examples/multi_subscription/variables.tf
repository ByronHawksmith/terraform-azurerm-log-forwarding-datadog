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

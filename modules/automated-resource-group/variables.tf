variable "resource_group_name" {
  description = <<-EOT
    Name of the resource group where resources will be created.

    CRITICAL: This name MUST match the resource group name used by the automation module.
    The scaling task uses a single RESOURCE_GROUP environment variable across all subscriptions,
    so all resource groups must have identical names.

    If the names don't match, the automation module will fail Terraform validation at plan time.
  EOT
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "Tags to apply to the resource group"
  type        = map(string)
  default     = {}
}
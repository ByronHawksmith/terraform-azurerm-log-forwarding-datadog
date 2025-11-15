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
    Terraform validation will fail if any monitored resource group has a different name.

    Example:
    {
      "00000000-0000-0000-0000-000000000001" = {
        subscription_id     = "00000000-0000-0000-0000-000000000001"
        resource_group_name = "rg-datadog-log-forwarding"  # Must match var.resource_group_name
      }
    }
  EOT
  type = map(object({
    subscription_id     = string
    resource_group_name = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for rg in values(var.monitored_resource_groups) :
      rg.resource_group_name == var.resource_group_name
    ])
    error_message = <<-EOT
      Validation failed: All monitored resource groups must have the same name as the control plane resource group.

      The scaling task (scaling_task.py) uses a single RESOURCE_GROUP environment variable to create
      and manage log forwarding resources across ALL subscriptions. This means every subscription must
      have a resource group with the identical name.

      Control plane resource group name: Check var.resource_group_name
      Monitored resource groups: One or more have mismatched names

      To fix: Ensure all resource groups in monitored_resource_groups use the same name as var.resource_group_name.

      Example:
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
  }
}

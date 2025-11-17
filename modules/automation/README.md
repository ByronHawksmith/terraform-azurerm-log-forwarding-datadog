# Datadog Azure Log Forwarding Automation - Control Plane Module

Use this Terraform module to deploy the control plane infrastructure for forwarding logs from Azure to Datadog. This module creates the resource group and related automation resources.

The module supports cross-subscription scenarios where function apps deployed in the control plane subscription need to create resources in resource groups located in other monitored subscriptions.

## ⚠️ Critical Constraints

**Resource Group Naming Requirement**: When deploying across multiple subscriptions, **all resource groups must have the exact same name**. This is not optional.

### Why This Matters

The Python scaling task (`scaling_task.py`) uses a single `RESOURCE_GROUP` environment variable to manage log forwarding resources across ALL subscriptions. It constructs Azure resource IDs using this single name:

```python
# In each subscription, the task creates resources in the same-named resource group
self.resource_group = get_config_option(RESOURCE_GROUP_SETTING)  # Single value for all subscriptions

async with LogForwarderClient(
    self.log, self.credential, subscription_id, self.resource_group, ...
) as client:
    # Creates storage accounts, managed environments, container apps in {subscription_id}/{self.resource_group}
```

### Terraform Validation

This module includes validation rules that will **fail at plan time** if any monitored resource group has a different name than the control plane resource group. This prevents misconfigurations from being deployed.

### Correct Pattern

```hcl
locals {
  resource_group_name = "rg-datadog-log-forwarding"  # Single name for ALL subscriptions
}

module "monitored_rg" {
  resource_group_name = local.resource_group_name  # Same name
}

module "automation" {
  resource_group_name = local.resource_group_name  # Same name
}
```

## Usage

### Basic Usage

```hcl
module "log_automation" {
  source = "DataDog/log-forwarding-datadog/azurerm//modules/automation"

  resource_group_name = "my-awesome-resource-group"
  location            = "East US"
  tags                = {}
}
```

### Cross-Subscription Usage

```hcl
# CRITICAL: Use the same resource group name across all subscriptions
locals {
  resource_group_name = "rg-datadog-log-forwarding"
}

# Deploy resource group in monitored subscription
module "monitored_rg" {
  source = "DataDog/log-forwarding-datadog/azurerm//modules/automated-resource-group"

  providers = {
    azurerm = azurerm.monitored
  }

  resource_group_name = local.resource_group_name  # Same name as control plane
  location            = "East US"
}

# Deploy control plane in control plane subscription
module "automation" {
  source = "DataDog/log-forwarding-datadog/azurerm//modules/automation"

  providers = {
    azurerm = azurerm.control_plane
  }

  resource_group_name = local.resource_group_name  # Same name as monitored
  location            = "East US"

  # Pass monitored resource group information for future function app permissions
  monitored_resource_groups = {
    (module.monitored_rg.subscription_id) = {
      subscription_id     = module.monitored_rg.subscription_id
      resource_group_name = module.monitored_rg.resource_group_name
    }
  }
}
```

See the [multi_subscription example](../../examples/multi_subscription/) for a complete cross-subscription setup.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | `"East US"` | no |
| <a name="input_monitored_resource_groups"></a> [monitored\_resource\_groups](#input\_monitored\_resource\_groups) | Map of subscription IDs to resource group information for monitored subscriptions.<br/>This is reserved for future use to grant function app permissions on resource groups<br/>in other subscriptions. The function app will be able to create resources in these<br/>resource groups using its managed identity.<br/><br/>CRITICAL: All resource\_group\_name values MUST match var.resource\_group\_name exactly.<br/>The scaling task uses a single RESOURCE\_GROUP environment variable across all subscriptions.<br/>You must ensure all monitored resource groups use the same name as the control plane resource group.<br/><br/>Example:<br/>{<br/>  "00000000-0000-0000-0000-000000000001" = {<br/>    subscription\_id     = "00000000-0000-0000-0000-000000000001"<br/>    resource\_group\_name = "rg-datadog-log-forwarding"  # Must match var.resource\_group\_name<br/>  }<br/>}<br/><br/>To ensure consistency, use a local variable:<br/>locals {<br/>  resource\_group\_name = "rg-datadog-log-forwarding"<br/>}<br/><br/>module "automation" {<br/>  resource\_group\_name = local.resource\_group\_name<br/>  monitored\_resource\_groups = {<br/>    "sub-id" = {<br/>      subscription\_id     = "sub-id"<br/>      resource\_group\_name = local.resource\_group\_name  # Same name!<br/>    }<br/>  }<br/>} | <pre>map(object({<br/>    subscription_id     = string<br/>    resource_group_name = string<br/>  }))</pre> | `{}` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where control plane resources will be created.<br/><br/>CRITICAL: When using multi-subscription deployment, all monitored subscriptions must have<br/>resource groups with this EXACT SAME NAME. The scaling task uses a single RESOURCE\_GROUP<br/>environment variable to manage resources across all subscriptions. This ensures consistent<br/>resource organization and simplified operations. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
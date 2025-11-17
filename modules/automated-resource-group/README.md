# Datadog Azure Log Forwarding Automation - Resource Group Module

Use this Terraform module to deploy a resource group to be used for forwarding logs from Azure to Datadog. This module is intended for adding an additional subscription to the automation deployed by the DataDog/log-forwarding-datadog/azurerm//modules/automation module.

This module outputs resource group information that can be passed to the automation module for cross-subscription permissions management.

## ⚠️ Critical Naming Requirement

**All resource groups across subscriptions MUST use the same name.** This is enforced by the automation module's validation rules.

The Python scaling task uses a single `RESOURCE_GROUP` environment variable to manage resources across all subscriptions. If you use different resource group names in different subscriptions, the automation module will fail Terraform validation at plan time.

### Correct Pattern

```hcl
# Use a local variable to ensure consistent naming
locals {
  resource_group_name = "rg-datadog-log-forwarding"
}

module "monitored_resource_group" {
  resource_group_name = local.resource_group_name  # Same name
}

module "automation" {
  resource_group_name = local.resource_group_name  # Same name
}
```

See the [automation module documentation](../automation/README.md#-critical-constraints) for detailed explanation of why this constraint exists.

## Usage

```hcl
# CRITICAL: Use the same resource group name as the automation module
locals {
  resource_group_name = "rg-datadog-log-forwarding"
}

module "monitored_resource_group" {
  source = "DataDog/log-forwarding-datadog/azurerm//modules/automated-resource-group"

  resource_group_name = local.resource_group_name  # Must match automation module
  location            = "East US"
  tags                = {}
}

# Pass outputs to automation module for cross-subscription setup
module "automation" {
  source = "DataDog/log-forwarding-datadog/azurerm//modules/automation"

  resource_group_name = local.resource_group_name  # Same name as above

  monitored_resource_groups = {
    (module.monitored_resource_group.subscription_id) = {
      subscription_id     = module.monitored_resource_group.subscription_id
      resource_group_name = module.monitored_resource_group.resource_group_name
    }
  }
}
```

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
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | `"East US"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where resources will be created.<br/><br/>CRITICAL: This name MUST match the resource group name used by the automation module.<br/>The scaling task uses a single RESOURCE\_GROUP environment variable across all subscriptions,<br/>so all resource groups must have identical names.<br/><br/>If the names don't match, the automation module will fail Terraform validation at plan time. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the resource group | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | The ID of the created resource group |
| <a name="output_resource_group_location"></a> [resource\_group\_location](#output\_resource\_group\_location) | The location of the created resource group |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The name of the created resource group |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | The subscription ID where the resource group was created |
<!-- END_TF_DOCS -->
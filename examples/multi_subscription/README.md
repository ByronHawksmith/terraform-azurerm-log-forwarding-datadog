# Multi-Subscription Datadog Log Forwarding Example

This example demonstrates how to deploy Datadog log forwarding automation across multiple Azure subscriptions. The architecture separates the control plane (automation infrastructure) from the monitored resources, enabling centralized management while maintaining subscription isolation for billing and governance purposes.

## ⚠️ Critical Requirements

### Resource Group Naming Constraint

**ALL resource groups across ALL subscriptions MUST have the EXACT SAME NAME.** This is not optional and is enforced by Terraform validation.

The Python scaling task (`scaling_task.py`) in the automation infrastructure uses a single `RESOURCE_GROUP` environment variable to manage resources across all subscriptions. The task constructs Azure resource IDs like this:

```python
# In ScalingTask.__init__
self.resource_group = get_config_option(RESOURCE_GROUP_SETTING)  # Single value for all subscriptions

# In process_subscription
async with LogForwarderClient(
    self.log, self.credential, subscription_id, self.resource_group, ...
) as client:
    # Creates resources in /subscriptions/{subscription_id}/resourceGroups/{self.resource_group}
```

Because `self.resource_group` is a single value, all subscriptions must have a resource group with that exact name.

### Terraform Validation

This example uses the automation module's built-in validation to prevent misconfigurations:

```hcl
# This will PASS validation (same name everywhere)
locals {
  resource_group_name = "rg-datadog-log-forwarding"
}
module "monitored_rg" { resource_group_name = local.resource_group_name }
module "automation" { resource_group_name = local.resource_group_name }

# This will FAIL validation at terraform plan (different names)
module "monitored_rg" { resource_group_name = "rg-monitored" }
module "automation" { resource_group_name = "rg-control-plane" }
```

If validation fails, you'll see an error message explaining the requirement and how to fix it.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure AD Tenant                               │
│                                                                  │
│  ┌─────────────────────────────┐  ┌──────────────────────────┐ │
│  │ Subscription A (Control)    │  │ Subscription B (Monitor) │ │
│  │                             │  │                          │ │
│  │  ┌────────────────────┐    │  │  ┌─────────────────┐    │ │
│  │  │ Resource Group     │    │  │  │ Resource Group  │    │ │
│  │  │                    │    │  │  │                 │    │ │
│  │  │  • Automation      │────┼──┼─▶│  [Monitored]    │    │ │
│  │  │    Infrastructure  │    │  │  │  [Resources]    │    │ │
│  │  │                    │    │  │  └─────────────────┘    │ │
│  │  │  • Future:         │    │  │                          │ │
│  │  │    Function App    │    │  │                          │ │
│  │  │    w/ Managed      │    │  │                          │ │
│  │  │    Identity        │    │  │                          │ │
│  │  └────────────────────┘    │  │                          │ │
│  │           │                 │  │                          │ │
│  │           └─────────────────┼──┼──────────────────────────┤ │
│  │    Contributor Role         │  │   (Cross-Subscription)   │ │
│  │    Assignment on RG ────────┼──┘                          │ │
│  └─────────────────────────────┘                             │ │
│                                                               │ │
└───────────────────────────────────────────────────────────────┘
```

## Key Concepts

### Cross-Subscription Permissions

This example sets up the foundation for cross-subscription resource management using Azure's role-based access control (RBAC). Here's how it works:

1. **Managed Identity in Control Plane**: When a function app is deployed in the control plane subscription, it receives a system-assigned managed identity with a globally unique `principal_id`.

2. **Role Assignment Scope Strings**: Azure role assignments use scope strings like `/subscriptions/{id}/resourceGroups/{name}` that can reference resources across subscriptions within the same Azure AD tenant.

3. **Cross-Subscription Access**: The automation module can create role assignments that grant the function app's managed identity permissions on resource groups in other subscriptions:

   ```hcl
   resource "azurerm_role_assignment" "cross_subscription" {
     scope                = "/subscriptions/${monitored_sub_id}/resourceGroups/${monitored_rg_name}"
     role_definition_name = "Contributor"
     principal_id         = azurerm_function_app.app.identity[0].principal_id
   }
   ```

4. **Runtime Authentication**: At runtime, the function app authenticates using its managed identity token (valid tenant-wide) and can create resources in the monitored subscription's resource group because of the pre-granted permissions.

### Why This Architecture?

- **Least Privilege**: Function apps only have Contributor access to specific resource groups, not entire subscriptions
- **Centralized Control**: All automation logic lives in the control plane subscription
- **Flexible Monitoring**: Easy to add/remove monitored subscriptions without redeploying the function app
- **Cost Isolation**: Monitored resources can be in different subscriptions for billing/management purposes
- **Security Boundary**: Clear separation between control plane and monitored resources

## Prerequisites

### Azure AD Tenant Requirements
- Both subscriptions must be in the same Azure AD tenant
- Cross-tenant scenarios require different authentication patterns (not covered in this example)

### Terraform Execution Permissions
The identity running Terraform (service principal or user account) needs:

1. **In Control Plane Subscription**:
   - Permissions to create resource groups and automation resources
   - `Contributor` or similar role

2. **In Monitored Subscription**:
   - Permissions to create resource groups
   - `User Access Administrator` or `Owner` role to create role assignments
   - This is required because role assignments are resources that live in the subscription where the target resource exists

### Azure Provider Authentication
You can authenticate the Azure provider in several ways:

- **Service Principal**: Create a service principal with access to both subscriptions
- **Azure CLI**: Run `az login` with an account that has access to both subscriptions
- **Managed Identity**: When running in Azure (e.g., Azure DevOps), use managed identity with appropriate permissions

## Usage

### 1. Configure Variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your subscription IDs and preferences:

```hcl
control_plane_subscription_id = "your-control-plane-subscription-id"
monitored_subscription_id     = "your-monitored-subscription-id"
resource_group_name           = "rg-datadog-log-forwarding"  # CRITICAL: Same name for ALL subscriptions
location                      = "East US"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan
```

This will show you:
- Resource group creation in the monitored subscription
- Automation infrastructure creation in the control plane subscription
- The `monitored_resource_groups` variable being passed (currently not used by the automation module)

### 4. Apply the Configuration

```bash
terraform apply
```

### 5. Verify the Deployment

After deployment, verify:

```bash
# Check control plane resources
az group show --name rg-datadog-control-plane --subscription <control-plane-sub-id>

# Check monitored resource group
az group show --name rg-datadog-monitored-resources --subscription <monitored-sub-id>
```

## Future Function App Integration

The `monitored_resource_groups` variable is currently accepted by the automation module but not yet used. When function apps are added to the automation module in the future, they will:

1. **Be created with managed identity** in the control plane subscription
2. **Receive role assignments** on the monitored resource groups using scope strings
3. **Create resources at runtime** in the monitored subscriptions using their managed identity

Example of future IAM configuration in the automation module:

```hcl
# This will be added to modules/automation/iam.tf in the future
resource "azurerm_role_assignment" "function_app_contributor" {
  for_each = var.monitored_resource_groups

  scope                = "/subscriptions/${each.value.subscription_id}/resourceGroups/${each.value.resource_group_name}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_function_app.forwarder.identity[0].principal_id
}
```

## Multiple Monitored Subscriptions

This example demonstrates a single monitored subscription, but the pattern scales to multiple monitored subscriptions:

```hcl
module "monitored_rg_1" {
  source = "../../modules/automated-resource-group"
  providers = { azurerm = azurerm.monitored_1 }
  # ...
}

module "monitored_rg_2" {
  source = "../../modules/automated-resource-group"
  providers = { azurerm = azurerm.monitored_2 }
  # ...
}

module "automation" {
  source = "../../modules/automation"

  monitored_resource_groups = {
    (module.monitored_rg_1.subscription_id) = {
      subscription_id     = module.monitored_rg_1.subscription_id
      resource_group_name = module.monitored_rg_1.resource_group_name
    }
    (module.monitored_rg_2.subscription_id) = {
      subscription_id     = module.monitored_rg_2.subscription_id
      resource_group_name = module.monitored_rg_2.resource_group_name
    }
  }
}
```

## Troubleshooting

### "Insufficient permissions to create role assignment"

**Cause**: The identity running Terraform doesn't have `User Access Administrator` or `Owner` role in the monitored subscription.

**Solution**: Grant the Terraform execution identity appropriate permissions:
```bash
az role assignment create \
  --assignee <terraform-identity-object-id> \
  --role "User Access Administrator" \
  --subscription <monitored-subscription-id>
```

### "Subscription not found"

**Cause**: The Azure provider can't access one or both subscriptions.

**Solution**:
1. Verify you're authenticated: `az account list`
2. Ensure the subscriptions are in the same tenant
3. Verify the subscription IDs are correct

### Role assignments not working at runtime

**Cause**: Role assignments can take up to 5 minutes to propagate in Azure.

**Solution**: Wait a few minutes after deployment before testing cross-subscription access.

## Security Considerations

1. **Least Privilege**: This example uses Contributor role on specific resource groups. Review whether more restrictive roles would meet your needs.

2. **Audit Logging**: Enable Azure Activity Logs to track cross-subscription resource operations.

3. **Resource Locks**: Consider applying locks to critical resource groups to prevent accidental deletion.

4. **Network Isolation**: For production deployments, consider using Private Endpoints and Virtual Network integration to restrict network access.

## Clean Up

To remove all resources:

```bash
terraform destroy
```

This will remove:
- The resource group in the monitored subscription
- The automation infrastructure in the control plane subscription
- All associated role assignments

## References

- [Azure RBAC Documentation](https://docs.microsoft.com/azure/role-based-access-control/)
- [Managed Identity Documentation](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Terraform Azure Provider Configuration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_automation"></a> [automation](#module\_automation) | ../../modules/automation | n/a |
| <a name="module_monitored_resource_group"></a> [monitored\_resource\_group](#module\_monitored\_resource\_group) | ../../modules/automated-resource-group | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_control_plane_subscription_id"></a> [control\_plane\_subscription\_id](#input\_control\_plane\_subscription\_id) | Azure subscription ID where the control plane automation infrastructure will be deployed | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | `"East US"` | no |
| <a name="input_monitored_subscription_id"></a> [monitored\_subscription\_id](#input\_monitored\_subscription\_id) | Azure subscription ID that will be monitored by the Datadog log forwarding automation | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group to use across ALL subscriptions.<br/><br/>CRITICAL: This same name will be used for the resource group in BOTH the control plane<br/>subscription and the monitored subscription. The scaling task uses a single RESOURCE\_GROUP<br/>environment variable to manage resources across all subscriptions, so all resource groups<br/>must have identical names.<br/><br/>The automation module includes validation that will fail if monitored resource groups<br/>don't match this name. | `string` | `"rg-datadog-log-forwarding"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | <pre>{<br/>  "environment": "example",<br/>  "managed_by": "terraform"<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

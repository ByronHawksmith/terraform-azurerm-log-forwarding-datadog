# Datadog Azure Log Forwarding Automation - Control Plane Module

Use this Terraform module to deploy the control plane infrastructure for forwarding logs from Azure to Datadog. This module creates:

- **Resource Group**: Control plane resource group for all automation resources
- **Storage Account**: Shared storage for function apps, cache, and coordination (`lfostorage{control_plane_id}`)
- **App Service Plan**: Y1 (Consumption) plan for cost-effective serverless execution
- **Function Apps**: Three Python-based Azure Function Apps that form the orchestration engine:
  - **Resources Task**: Discovers and tracks all log-generating Azure resources across monitored subscriptions
  - **Scaling Task**: Intelligently manages log forwarder lifecycle - creates, scales, and deletes forwarders based on log volume
  - **Diagnostic Settings Task**: Automatically configures Azure Diagnostic Settings on discovered resources to route logs
- **Role Assignments**: Grants necessary permissions to function app managed identities across monitored subscriptions and resource groups

The module supports cross-subscription scenarios where function apps deployed in the control plane subscription need to create resources in resource groups located in other monitored subscriptions.

## Architecture Overview

The control plane operates on a timer-triggered schedule:

1. **Resources Task** (every 5 minutes): Scans monitored subscriptions for log-generating resources, applies tag filters, and caches results
2. **Scaling Task** (every 5 minutes, 30s offset): Analyzes forwarder performance metrics and scales infrastructure accordingly
3. **Diagnostic Settings Task** (every 5 minutes): Ensures all discovered resources have diagnostic settings configured to forward logs

All three function apps coordinate via shared blob storage cache and Azure APIs.

## Code Deployment

**Important**: This module provisions the infrastructure only. Function app code packages are deployed separately by a deployer task (Container App Job). The function apps will be created but remain empty until code is deployed. See the deployer task documentation for code deployment instructions.

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

  resource_group_name = "rg-datadog-log-forwarding"
  location            = "East US"

  # Datadog configuration
  datadog_api_key = var.datadog_api_key  # Sensitive - pass from variable
  datadog_site    = "datadoghq.com"

  # Optional: Provide control plane ID for predictable naming
  # If not provided, a random 12-character ID will be generated
  # control_plane_id = "myapp123"

  # Optional: Filter resources by tags
  # resource_tag_filters = "env:prod,!temporary:true"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
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

  # Datadog configuration
  datadog_api_key = var.datadog_api_key
  datadog_site    = "datadoghq.com"

  # Pass monitored resource group information for function app permissions
  monitored_resource_groups = {
    (module.monitored_rg.subscription_id) = {
      subscription_id     = module.monitored_rg.subscription_id
      resource_group_name = module.monitored_rg.resource_group_name
    }
  }

  # Optional: Advanced configuration
  log_level            = "INFO"
  resource_tag_filters = "env:prod"
  forwarder_image      = "datadoghq.azurecr.io/forwarder:latest"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Using Control Plane Outputs

The module provides outputs for integration with other modules:

```hcl
# Access function app principal IDs for additional role assignments
output "resources_task_principal" {
  value = module.automation.resources_task_principal_id
}

# Access storage connection string for deployer task
output "storage_connection" {
  value     = module.automation.storage_connection_string
  sensitive = true
}

# Access control plane ID for resource naming
output "control_plane_id" {
  value = module.automation.control_plane_id
}
```

See the [multi_subscription example](../../examples/multi_subscription/) for a complete cross-subscription setup.

## Function Apps and Permissions

### Resources Task

**Purpose**: Discovers and tracks all log-generating Azure resources across monitored subscriptions.

**Runtime**: Python 3.11, Timer trigger (every 5 minutes)

**Permissions Required**:
- `Monitoring Reader` on each monitored subscription (read-only resource discovery)

**App Settings**:
- `MONITORED_SUBSCRIPTIONS`: JSON array of subscription IDs to scan
- `RESOURCE_TAG_FILTERS`: Comma-separated tag filters for resource inclusion/exclusion

### Scaling Task

**Purpose**: Intelligently manages log forwarder lifecycle - creates, scales, and deletes forwarders based on actual log volume.

**Runtime**: Python 3.11, Timer trigger (every 5 minutes, 30s offset)

**Permissions Required**:
- `Contributor` on each monitored resource group (create/manage forwarder infrastructure)

**App Settings**:
- `RESOURCE_GROUP`: Resource group name (same across all subscriptions)
- `FORWARDER_IMAGE`: Container image for forwarder jobs
- `CONTROL_PLANE_REGION`: Azure region for control plane operations
- `PII_SCRUBBER_RULES`: YAML-formatted PII redaction rules
- `SCALING_PERCENTAGE`: Threshold for scaling decisions (default: 0.8)

### Diagnostic Settings Task

**Purpose**: Automatically configures Azure Diagnostic Settings on discovered resources to route logs to storage accounts.

**Runtime**: Python 3.11, Timer trigger (every 5 minutes)

**Permissions Required**:
- `Monitoring Contributor` on each monitored subscription (create/modify diagnostic settings)
- `Reader and Data Access` on each monitored resource group (read storage account information)

**App Settings**:
- `RESOURCE_GROUP`: Resource group name (same across all subscriptions)

## Storage Account

The module creates a shared storage account (`lfostorage{control_plane_id}`) used by all function apps:

- **File Share**: Function app content storage (50GB quota)
- **Blob Container**: `control-plane-cache` for resource/assignment/event caches
- **Lifecycle Policy**: Automatic deletion of cache blobs and function logs after 7 days (configurable via `cache_retention_days`)

**Naming Constraint**: Storage account name must be ≤24 characters, globally unique, lowercase alphanumeric only. The module enforces this by validating `control_plane_id` is ≤12 characters.

## Role Assignments

The module automatically creates role assignments for function app managed identities:

| Function App | Role | Scope | Purpose |
|--------------|------|-------|---------|
| Resources Task | Monitoring Reader | Subscription | Read-only resource discovery |
| Scaling Task | Contributor | Resource Group | Create/manage forwarder resources |
| Diagnostic Settings Task | Monitoring Contributor | Subscription | Create/modify diagnostic settings |
| Diagnostic Settings Task | Reader and Data Access | Resource Group | Read storage account data |

All role assignments include a description tag `ddlfo{control_plane_id}` for tracking and cleanup.

## Variable Reference

### Required Variables

- `resource_group_name`: Name of the control plane resource group (must match across all subscriptions)
- `datadog_api_key`: Datadog API key (sensitive)

### Optional Variables

- `control_plane_id`: Custom control plane identifier (default: auto-generated, max 12 chars)
- `location`: Azure region (default: "East US")
- `datadog_site`: Datadog site URL (default: "datadoghq.com")
- `datadog_telemetry`: Enable Datadog telemetry (default: false)
- `log_level`: Logging level (default: "INFO", options: DEBUG|INFO|WARNING|ERROR|CRITICAL)
- `resource_tag_filters`: Tag filters for resource discovery (default: "")
- `forwarder_image`: Container image for forwarders (default: "datadoghq.azurecr.io/forwarder:latest")
- `pii_scrubber_rules`: YAML PII scrubbing rules (default: "")
- `storage_replication_type`: Storage replication (default: "LRS", options: LRS|GRS|ZRS|GZRS)
- `cache_retention_days`: Cache retention in days (default: 7, range: 1-365)
- `monitored_resource_groups`: Map of monitored resource groups (default: {})
- `tags`: Resource tags (default: {})

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_function_app.diagnostic_settings_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_linux_function_app.resources_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_linux_function_app.scaling_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.diagnostic_settings_task_monitoring_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.diagnostic_settings_task_reader_data_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.resources_task_monitoring_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.scaling_task_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_service_plan.control_plane](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.control_plane](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.cache](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_storage_management_policy.lifecycle](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_management_policy) | resource |
| [azurerm_storage_share.function_content](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [random_string.control_plane_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_role_definition.contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/role_definition) | data source |
| [azurerm_role_definition.monitoring_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/role_definition) | data source |
| [azurerm_role_definition.monitoring_reader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/role_definition) | data source |
| [azurerm_role_definition.reader_data_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/role_definition) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cache_retention_days"></a> [cache\_retention\_days](#input\_cache\_retention\_days) | Number of days to retain cache blobs before automatic deletion | `number` | `7` | no |
| <a name="input_control_plane_id"></a> [control\_plane\_id](#input\_control\_plane\_id) | Optional control plane identifier. If not provided, a random 12-character alphanumeric<br/>string will be generated. This ID is used in resource naming to ensure uniqueness.<br/><br/>Requirements:<br/>- Must be lowercase alphanumeric only (a-z, 0-9)<br/>- Must be 12 characters or less<br/>- Will be used in storage account name (24 char limit: "lfostorage" + control\_plane\_id)<br/><br/>Example: "abc123def456" | `string` | `null` | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | Datadog API key for sending logs and metrics | `string` | n/a | yes |
| <a name="input_datadog_site"></a> [datadog\_site](#input\_datadog\_site) | Datadog site to send logs to. Options:<br/>- datadoghq.com (US1)<br/>- us3.datadoghq.com (US3)<br/>- us5.datadoghq.com (US5)<br/>- datadoghq.eu (EU1)<br/>- ddog-gov.com (US1-FED) | `string` | `"datadoghq.com"` | no |
| <a name="input_datadog_telemetry"></a> [datadog\_telemetry](#input\_datadog\_telemetry) | Enable Datadog telemetry for control plane function apps | `bool` | `false` | no |
| <a name="input_forwarder_image"></a> [forwarder\_image](#input\_forwarder\_image) | Container image for log forwarder jobs | `string` | `"datadoghq.azurecr.io/forwarder:latest"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | `"East US"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Logging level for control plane function apps | `string` | `"INFO"` | no |
| <a name="input_monitored_resource_groups"></a> [monitored\_resource\_groups](#input\_monitored\_resource\_groups) | Map of subscription IDs to resource group information for monitored subscriptions.<br/>This is reserved for future use to grant function app permissions on resource groups<br/>in other subscriptions. The function app will be able to create resources in these<br/>resource groups using its managed identity.<br/><br/>CRITICAL: All resource\_group\_name values MUST match var.resource\_group\_name exactly.<br/>The scaling task uses a single RESOURCE\_GROUP environment variable across all subscriptions.<br/>You must ensure all monitored resource groups use the same name as the control plane resource group.<br/><br/>Example:<br/>{<br/>  "00000000-0000-0000-0000-000000000001" = {<br/>    subscription\_id     = "00000000-0000-0000-0000-000000000001"<br/>    resource\_group\_name = "rg-datadog-log-forwarding"  # Must match var.resource\_group\_name<br/>  }<br/>}<br/><br/>To ensure consistency, use a local variable:<br/>locals {<br/>  resource\_group\_name = "rg-datadog-log-forwarding"<br/>}<br/><br/>module "automation" {<br/>  resource\_group\_name = local.resource\_group\_name<br/>  monitored\_resource\_groups = {<br/>    "sub-id" = {<br/>      subscription\_id     = "sub-id"<br/>      resource\_group\_name = local.resource\_group\_name  # Same name!<br/>    }<br/>  }<br/>} | <pre>map(object({<br/>    subscription_id     = string<br/>    resource_group_name = string<br/>  }))</pre> | `{}` | no |
| <a name="input_pii_scrubber_rules"></a> [pii\_scrubber\_rules](#input\_pii\_scrubber\_rules) | YAML-formatted PII scrubbing rules for log redaction.<br/>Applied to logs before forwarding to Datadog.<br/><br/>Example:<br/>rules:<br/>  - name: "Redact SSN"<br/>    pattern: '\d{3}-\d{2}-\d{4}'<br/>    replacement: '[REDACTED-SSN]' | `string` | `""` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where control plane resources will be created.<br/><br/>CRITICAL: When using multi-subscription deployment, all monitored subscriptions must have<br/>resource groups with this EXACT SAME NAME. The scaling task uses a single RESOURCE\_GROUP<br/>environment variable to manage resources across all subscriptions. This ensures consistent<br/>resource organization and simplified operations. | `string` | n/a | yes |
| <a name="input_resource_tag_filters"></a> [resource\_tag\_filters](#input\_resource\_tag\_filters) | Comma-separated list of tag filters for resource discovery.<br/>Use '!' prefix to exclude resources with specific tags.<br/><br/>Examples:<br/>- "env:prod,team:platform" - Include resources with these tags<br/>- "!env:dev" - Exclude dev environment resources<br/>- "env:prod,!temporary:true" - Include prod but exclude temporary resources | `string` | `""` | no |
| <a name="input_storage_replication_type"></a> [storage\_replication\_type](#input\_storage\_replication\_type) | Storage account replication type for control plane storage | `string` | `"LRS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_control_plane_id"></a> [control\_plane\_id](#output\_control\_plane\_id) | The control plane identifier used for resource naming |
| <a name="output_diagnostic_settings_task_principal_id"></a> [diagnostic\_settings\_task\_principal\_id](#output\_diagnostic\_settings\_task\_principal\_id) | Managed identity principal ID of the diagnostic settings task function app (for additional role assignments) |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the automation resource group |
| <a name="output_resources_task_principal_id"></a> [resources\_task\_principal\_id](#output\_resources\_task\_principal\_id) | Managed identity principal ID of the resources task function app (for additional role assignments) |
| <a name="output_scaling_task_principal_id"></a> [scaling\_task\_principal\_id](#output\_scaling\_task\_principal\_id) | Managed identity principal ID of the scaling task function app (for additional role assignments) |
<!-- END_TF_DOCS -->
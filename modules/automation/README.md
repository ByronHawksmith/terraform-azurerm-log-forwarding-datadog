## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.53.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_app_environment.deployer_env](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_container_app_job.deployer_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job) | resource |
| [azurerm_linux_function_app.diagnostic_settings_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_linux_function_app.resources_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_linux_function_app.scaling_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.deployer_task_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.deployer_task_monitoring_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.deployer_task_website_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
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
| [azurerm_role_definition.website_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/role_definition) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cache_retention_days"></a> [cache\_retention\_days](#input\_cache\_retention\_days) | Number of days to retain cache blobs before automatic deletion | `number` | `7` | no |
| <a name="input_control_plane_id"></a> [control\_plane\_id](#input\_control\_plane\_id) | Optional control plane identifier. If not provided, a random 12-character alphanumeric<br/>string will be generated. This ID is used in resource naming to ensure uniqueness.<br/><br/>Requirements:<br/>- Must be lowercase alphanumeric only (a-z, 0-9)<br/>- Must be 12 characters or less<br/>- Will be used in storage account name (24 char limit: "lfostorage" + control\_plane\_id)<br/><br/>Example: "abc123def456" | `string` | `null` | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | Datadog API key for sending logs and metrics | `string` | n/a | yes |
| <a name="input_datadog_site"></a> [datadog\_site](#input\_datadog\_site) | Datadog site to send logs to. Options:<br/>- datadoghq.com (US1)<br/>- us3.datadoghq.com (US3)<br/>- us5.datadoghq.com (US5)<br/>- datadoghq.eu (EU1)<br/>- ddog-gov.com (US1-FED) | `string` | `"datadoghq.com"` | no |
| <a name="input_datadog_telemetry"></a> [datadog\_telemetry](#input\_datadog\_telemetry) | Enable Datadog telemetry for control plane function apps | `bool` | `false` | no |
| <a name="input_deployer_image_tag"></a> [deployer\_image\_tag](#input\_deployer\_image\_tag) | Tag for the deployer container image | `string` | `"latest"` | no |
| <a name="input_deployer_schedule"></a> [deployer\_schedule](#input\_deployer\_schedule) | Cron expression for deployer task schedule.<br/>Default is "*/30 * * * *" (every 30 minutes).<br/>Format: minute hour day month weekday | `string` | `"*/30 * * * *"` | no |
| <a name="input_forwarder_image"></a> [forwarder\_image](#input\_forwarder\_image) | Container image for log forwarder jobs | `string` | `"datadoghq.azurecr.io/forwarder:latest"` | no |
| <a name="input_image_registry"></a> [image\_registry](#input\_image\_registry) | Container registry for the deployer container image | `string` | `"datadoghq.azurecr.io"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | `"East US"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Logging level for control plane function apps | `string` | `"INFO"` | no |
| <a name="input_monitored_resource_groups"></a> [monitored\_resource\_groups](#input\_monitored\_resource\_groups) | Map of subscription IDs to resource group information for monitored subscriptions.<br/>This is reserved for future use to grant function app permissions on resource groups<br/>in other subscriptions. The function app will be able to create resources in these<br/>resource groups using its managed identity.<br/><br/>CRITICAL: All resource\_group\_name values MUST match var.resource\_group\_name exactly.<br/>The scaling task uses a single RESOURCE\_GROUP environment variable across all subscriptions.<br/>Terraform validation will fail if any monitored resource group has a different name.<br/><br/>Example:<br/>{<br/>  "00000000-0000-0000-0000-000000000001" = {<br/>    subscription\_id     = "00000000-0000-0000-0000-000000000001"<br/>    resource\_group\_name = "rg-datadog-log-forwarding"  # Must match var.resource\_group\_name<br/>  }<br/>} | <pre>map(object({<br/>    subscription_id     = string<br/>    resource_group_name = string<br/>  }))</pre> | `{}` | no |
| <a name="input_pii_scrubber_rules"></a> [pii\_scrubber\_rules](#input\_pii\_scrubber\_rules) | YAML-formatted PII scrubbing rules for log redaction.<br/>Applied to logs before forwarding to Datadog.<br/><br/>Example:<br/>rules:<br/>  - name: "Redact SSN"<br/>    pattern: '\d{3}-\d{2}-\d{4}'<br/>    replacement: '[REDACTED-SSN]' | `string` | `""` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where control plane resources will be created.<br/><br/>CRITICAL: When using multi-subscription deployment, all monitored subscriptions must have<br/>resource groups with this EXACT SAME NAME. The scaling task uses a single RESOURCE\_GROUP<br/>environment variable to manage resources across all subscriptions. This ensures consistent<br/>resource organization and simplified operations. | `string` | n/a | yes |
| <a name="input_resource_tag_filters"></a> [resource\_tag\_filters](#input\_resource\_tag\_filters) | Comma-separated list of tag filters for resource discovery.<br/>Use '!' prefix to exclude resources with specific tags.<br/><br/>Examples:<br/>- "env:prod,team:platform" - Include resources with these tags<br/>- "!env:dev" - Exclude dev environment resources<br/>- "env:prod,!temporary:true" - Include prod but exclude temporary resources | `string` | `""` | no |
| <a name="input_storage_account_url"></a> [storage\_account\_url](#input\_storage\_account\_url) | URL of the public storage account containing function app deployment packages.<br/>The deployer task downloads function app code from this storage account.<br/>If not specified, defaults to https://ddazurelfo.blob.core.windows.net | `string` | `"https://ddazurelfo.blob.core.windows.net"` | no |
| <a name="input_storage_replication_type"></a> [storage\_replication\_type](#input\_storage\_replication\_type) | Storage account replication type for control plane storage | `string` | `"LRS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_app_environment_id"></a> [container\_app\_environment\_id](#output\_container\_app\_environment\_id) | Resource ID of the container app environment |
| <a name="output_container_app_environment_name"></a> [container\_app\_environment\_name](#output\_container\_app\_environment\_name) | Name of the container app environment |
| <a name="output_control_plane_id"></a> [control\_plane\_id](#output\_control\_plane\_id) | The control plane identifier used for resource naming |
| <a name="output_deployer_task_id"></a> [deployer\_task\_id](#output\_deployer\_task\_id) | Resource ID of the deployer container app job |
| <a name="output_deployer_task_name"></a> [deployer\_task\_name](#output\_deployer\_task\_name) | Name of the deployer container app job |
| <a name="output_deployer_task_principal_id"></a> [deployer\_task\_principal\_id](#output\_deployer\_task\_principal\_id) | Managed identity principal ID of the deployer task (for additional role assignments) |
| <a name="output_diagnostic_settings_task_principal_id"></a> [diagnostic\_settings\_task\_principal\_id](#output\_diagnostic\_settings\_task\_principal\_id) | Managed identity principal ID of the diagnostic settings task function app (for additional role assignments) |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the automation resource group |
| <a name="output_resources_task_principal_id"></a> [resources\_task\_principal\_id](#output\_resources\_task\_principal\_id) | Managed identity principal ID of the resources task function app (for additional role assignments) |
| <a name="output_scaling_task_principal_id"></a> [scaling\_task\_principal\_id](#output\_scaling\_task\_principal\_id) | Managed identity principal ID of the scaling task function app (for additional role assignments) |

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
| [azurerm_container_app_environment.deployer_env](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_container_app_job.deployer_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job) | resource |
| [azurerm_linux_function_app.diagnostic_settings_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_linux_function_app.resources_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_linux_function_app.scaling_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.deployer_task_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.deployer_task_monitoring_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.deployer_task_website_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
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
| [azurerm_role_definition.website_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/role_definition) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cache_retention_days"></a> [cache\_retention\_days](#input\_cache\_retention\_days) | Number of days to retain cache blobs before automatic deletion | `number` | `7` | no |
| <a name="input_control_plane_id"></a> [control\_plane\_id](#input\_control\_plane\_id) | Optional control plane identifier. If not provided, a random 12-character alphanumeric<br/>string will be generated. This ID is used in resource naming to ensure uniqueness.<br/><br/>Requirements:<br/>- Must be lowercase alphanumeric only (a-z, 0-9)<br/>- Must be 12 characters or less<br/>- Will be used in storage account name (24 char limit: "lfostorage" + control\_plane\_id)<br/><br/>Example: "abc123def456" | `string` | `null` | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | Datadog API key for sending logs and metrics | `string` | n/a | yes |
| <a name="input_datadog_site"></a> [datadog\_site](#input\_datadog\_site) | Datadog site to send logs to. Options:<br/>- datadoghq.com (US1)<br/>- us3.datadoghq.com (US3)<br/>- us5.datadoghq.com (US5)<br/>- datadoghq.eu (EU1)<br/>- ap1.datadoghq.com (AP1)<br/>- ap2.datadoghq.com (AP2)<br/>- ddog-gov.com (US1-FED) | `string` | n/a | yes |
| <a name="input_datadog_telemetry"></a> [datadog\_telemetry](#input\_datadog\_telemetry) | Enable Datadog telemetry for control plane function apps | `bool` | `false` | no |
| <a name="input_deployer_image_tag"></a> [deployer\_image\_tag](#input\_deployer\_image\_tag) | Tag for the deployer container image | `string` | `"latest"` | no |
| <a name="input_deployer_schedule"></a> [deployer\_schedule](#input\_deployer\_schedule) | Cron expression for deployer task schedule.<br/>Default is "*/30 * * * *" (every 30 minutes).<br/>Format: minute hour day month weekday | `string` | `"*/30 * * * *"` | no |
| <a name="input_forwarder_image"></a> [forwarder\_image](#input\_forwarder\_image) | Container image for log forwarder jobs | `string` | `"datadoghq.azurecr.io/forwarder:latest"` | no |
| <a name="input_image_registry"></a> [image\_registry](#input\_image\_registry) | Container registry for the deployer container image | `string` | `"datadoghq.azurecr.io"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | `"East US"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Logging level for control plane function apps | `string` | `"INFO"` | no |
| <a name="input_monitored_resource_groups"></a> [monitored\_resource\_groups](#input\_monitored\_resource\_groups) | Map of subscription IDs to resource group information for monitored subscriptions.<br/>This is reserved for future use to grant function app permissions on resource groups<br/>in other subscriptions. The function app will be able to create resources in these<br/>resource groups using its managed identity.<br/><br/>CRITICAL: All resource\_group\_name values MUST match var.resource\_group\_name exactly.<br/>The scaling task uses a single RESOURCE\_GROUP environment variable across all subscriptions.<br/>You must ensure all monitored resource groups use the same name as the control plane resource group.<br/><br/>Example:<br/>{<br/>  "00000000-0000-0000-0000-000000000001" = {<br/>    subscription\_id     = "00000000-0000-0000-0000-000000000001"<br/>    resource\_group\_name = "rg-datadog-log-forwarding"  # Must match var.resource\_group\_name<br/>  }<br/>}<br/><br/>To ensure consistency, use a local variable:<br/>locals {<br/>  resource\_group\_name = "rg-datadog-log-forwarding"<br/>}<br/><br/>module "automation" {<br/>  resource\_group\_name = local.resource\_group\_name<br/>  monitored\_resource\_groups = {<br/>    "sub-id" = {<br/>      subscription\_id     = "sub-id"<br/>      resource\_group\_name = local.resource\_group\_name  # Same name!<br/>    }<br/>  }<br/>} | <pre>map(object({<br/>    subscription_id     = string<br/>    resource_group_name = string<br/>  }))</pre> | `{}` | no |
| <a name="input_pii_scrubber_rules"></a> [pii\_scrubber\_rules](#input\_pii\_scrubber\_rules) | YAML-formatted PII scrubbing rules for log redaction.<br/>Applied to logs before forwarding to Datadog.<br/><br/>Example:<br/>rules:<br/>  - name: "Redact SSN"<br/>    pattern: '\d{3}-\d{2}-\d{4}'<br/>    replacement: '[REDACTED-SSN]' | `string` | `""` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where control plane resources will be created.<br/><br/>CRITICAL: When using multi-subscription deployment, all monitored subscriptions must have<br/>resource groups with this EXACT SAME NAME. The scaling task uses a single RESOURCE\_GROUP<br/>environment variable to manage resources across all subscriptions. This ensures consistent<br/>resource organization and simplified operations. | `string` | n/a | yes |
| <a name="input_resource_tag_filters"></a> [resource\_tag\_filters](#input\_resource\_tag\_filters) | Comma-separated list of tag filters for resource discovery.<br/>Use '!' prefix to exclude resources with specific tags.<br/><br/>Examples:<br/>- "env:prod,team:platform" - Include resources with these tags<br/>- "!env:dev" - Exclude dev environment resources<br/>- "env:prod,!temporary:true" - Include prod but exclude temporary resources | `string` | `""` | no |
| <a name="input_storage_account_url"></a> [storage\_account\_url](#input\_storage\_account\_url) | URL of the public storage account containing function app deployment packages.<br/>The deployer task downloads function app code from this storage account.<br/>If not specified, defaults to https://ddazurelfo.blob.core.windows.net | `string` | `"https://ddazurelfo.blob.core.windows.net"` | no |
| <a name="input_storage_replication_type"></a> [storage\_replication\_type](#input\_storage\_replication\_type) | Storage account replication type for control plane storage | `string` | `"LRS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_app_environment_id"></a> [container\_app\_environment\_id](#output\_container\_app\_environment\_id) | Resource ID of the container app environment |
| <a name="output_container_app_environment_name"></a> [container\_app\_environment\_name](#output\_container\_app\_environment\_name) | Name of the container app environment |
| <a name="output_control_plane_id"></a> [control\_plane\_id](#output\_control\_plane\_id) | The control plane identifier used for resource naming |
| <a name="output_deployer_task_id"></a> [deployer\_task\_id](#output\_deployer\_task\_id) | Resource ID of the deployer container app job |
| <a name="output_deployer_task_name"></a> [deployer\_task\_name](#output\_deployer\_task\_name) | Name of the deployer container app job |
| <a name="output_deployer_task_principal_id"></a> [deployer\_task\_principal\_id](#output\_deployer\_task\_principal\_id) | Managed identity principal ID of the deployer task (for additional role assignments) |
| <a name="output_diagnostic_settings_task_principal_id"></a> [diagnostic\_settings\_task\_principal\_id](#output\_diagnostic\_settings\_task\_principal\_id) | Managed identity principal ID of the diagnostic settings task function app (for additional role assignments) |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the automation resource group |
| <a name="output_resources_task_principal_id"></a> [resources\_task\_principal\_id](#output\_resources\_task\_principal\_id) | Managed identity principal ID of the resources task function app (for additional role assignments) |
| <a name="output_scaling_task_principal_id"></a> [scaling\_task\_principal\_id](#output\_scaling\_task\_principal\_id) | Managed identity principal ID of the scaling task function app (for additional role assignments) |
<!-- END_TF_DOCS -->
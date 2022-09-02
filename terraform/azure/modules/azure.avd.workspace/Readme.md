# Terraform module to create a Azure Virtual Desktop Workspace
This module creates a Azure Virtual Desktop Workspace

### Inputs 

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azure_region | Azure region of deployment. | `string` | westeurope | yes |
| avd_workspace_name | Specifies the name of the  Azure Virtual Desktop Workspace. | `string` | n/a | yes |
| prefix | prefix of the workspace | `string` | n/a | yes
| avd_rg_name | The name of the resource group in which to create the  Azure Virtual Desktop Workspace. | `string` | n/a | yes |
| tags | A mapping of tags which should be assigned to the resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| avdworkspace_id | The Azure Virtual Desktop Workspace id. |

### Usage 
```
module "avd_worksplace" {
  source = "../modules/azure/avd_workspace"

  azure_region                    = "westeurope"
  avd_workspace_name              = "test-example-as"
  avd_rg_name                     = "test-example-rg"
  prefix                          = "avd"
  tags                            = {"env"="dev"}
}
```
# Terraform module to create a Azure Virtual Desktop Hostpool
This module creates a Azure Virtual Desktop Hostpool


### Inputs 

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| avd_hp_rg | resourcegroup where the hostpool will be deployed. | `string` |  | yes |
| location | Specifies the location where the hostpool will be deployed. | `string` | west-europe | yes |
| avd_hp_name | Specifies the name of the hostpool | `string` | n/a | yes
| avd_hp_friendlyname | Specifies the friendly name for the hostpool | `string` | n/a | yes |
| avd_hp_validate | Does the hostpool require validation | `bool` | `false` | no |
| avd_hp_custom_rdp_properties | Custom RDP Properties for hostpool | `string` | audiocapturemode:i:1;audiomode:i:0;targetisaadjoined:i:1; | no |
| avd_hp_desc | Description of the hostpool | `string` | n/a | no |
| avd_hp_type  | Type of the hostpool this can be Pooled or Personal | `string` | pooled | yes | 
| avd_hp_maxsessions | Maximum sessions on a host of the hostpool if avd_hp_type is Pooled, otherwise null | `string` | 16 | yes |
| avd_hp_lbtype | Loadbalacing type if the hostpool avd_hp_type is Personal this can be BreadthFirst or DepthFirst otherwise null | `string` | DepthFirst | no |
| avd_hp_personaldesktopassignment_type | Personal Desktop Assignment Type, when the avd_hp_type is Personal this can be Dynamic or Direct otherwise null | `string` | Dynamic | no |

## Outputs

| Name | Description |
|------|-------------|
| hostpool_id | The Azure Virtual Desktop hostpool id. |
| azure_virtual_desktop_host_pool | The Azure Virtual Desktop hostpool name | 
| hostpool_token |  The token to join vms into the hostpool (secret) | 

### Usage 
```
module "azure.avd.hostpool" {
  source = "../modules/azure.avd.hostpool"

  avd_hp_rg                             = "my-resource-group"
  azure_region                          = "westeurope"
  avd_hp_name                           = "AVD-test-module"
  avd_hp_friendlyname                   = "AVD-test-module"
  avd_hp_validate                       = false
  avd_hp_custom_rdp_properties          = "audiocapturemode:i:1;audiomode:i:0;targetisaadjoined:i:1;"
  avd_hp_desc                           = "my description"
  avd_hp_type                           = "Pooled"
  avd_hp_maxsessions                    = "16"
  avd_hp_lbtype                         = "DepthFirst"
  avd_hp_personaldesktopassignment_type = null

}
```
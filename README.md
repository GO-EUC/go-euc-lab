![feature-image](/.assets/images/feature_image.png)

Welcome to the GO-EUC lab configuration repository. This repository showcases how the GO-EUC lab is set up and is used as the primary deployment method for the GO-EUC platform.

> Please note: this repository is a work in progress.

## Overview
| Platform | Delivery Model | Status |
| :---- | :---- | :---- |
| Azure | None | MVP |
| Azure | Citrix Virtual Apps & Desktops Service | In progress |
| Azure | Azure Virtual Desktop | In progress |
| Azure | VMware Horizon Cloud | Todo |
| AWS | None | Todo |
| AWS | Amazon Workspaces | Todo |
| AWS | Citrix Virtual Apps & Desktops Service | Todo |
| AWS | VMware Horizon Cloud | Todo |
| GCP | None | Todo |
| GCP | Citrix Virtual Apps & Desktops Service | Todo |
| GCP | VMware Horizon Cloud | Todo |
| vSphere | None | In progress |
| vSphere | Citrix Virtual Apps & Desktops Service | Todo |
| vSphere | VMware Horizon Cloud | Todo |

## Technology Stack
The following technology stack in this project:
| Tech | Purpose |
| :----- | :----- |
| Azure DevOps | Primary deployment pipeline, can be replaced by GitHub actions or other DevOps solutions. |
| Terraform | Infrastructure provisioning. |
| Packer | Golden image management. |
| Ansible | Desired State Configuration. |
| Docker | Containers, primarily used for Azure DevOps agent and GO-EUC web services. |

## Prerequisite Microsoft Azure
Before getting started the following prerequisite needs to be in place:
Service principal account:
In order to deploy the infrastructure in Microsoft Azure, a service principal account needs to be created using these [instructions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret).
Azure Storage for state file
When using Microsoft Azure it makes sense the use an Azure storage account for storing the Terraform state configuration. Follow these [instructions](https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli) to create the storage account.

## Prerequisite Citrix Virtual Apps & Desktops Service
When using the Citrix Virtual Apps & Desktops Service delivery model API access key is required, which can be created using these [instructions](https://developer.cloud.com/citrix-cloud/citrix-cloud-api-overview/docs/get-started-with-citrix-cloud-apis).

## Prerequisite Azure DevOps
The Azure DevOps pipelines make use of variable groups which is linked to a specific individual that contains the following variables:
| Variable | Purpose |
| :------ | :------ | 
| azure_backend | Azure backend configuration file name, that needs to be available in the secure files |
| azure_client_id | Azure Service Principal client id |
| azure_client_secret | Azure Service Principal secret |
| azure_subscription_id | Azure Subscription id |
| azure_tenant_id | Azure Tenant id |
| devops_token | Azure DevOps personal access token, need to be able to create an Azure DevOps agent pool |
| citrix_client_id | Citrix Cloud API client id, when CVADs is used |
| citrix_client_secret | Citrix Cloud API secret, when CVADs is used |
| citrix_org_id | Citrix Cloud organization id, when CVADs is used |

In the secure file, the backend configuration for Terraform is stored, which can be created using the following [instructions](https://www.terraform.io/language/settings/backends/configuration#file).

The following properties are required in the backend configuration:
  * storage_account_name
  * container_name
  * key
  * access_key

## Primary contributors
This project is maintained by the following GO-EUC members:

  * [Anton van Pelt](https://www.go-euc.com/members/anton-van-pelt/)
  * [Patrick van den Born](https://www.go-euc.com/members/patrick-van-den-born/)
  * [Tom de Jong](https://www.go-euc.com/members/tom-de-jong/)
  * [Ryan Ververs-Bijkerk](https://www.go-euc.com/members/ryan-ververs-bijkerk/)

## Contributions
This project is initiated by GO-EUC and is maintained by multiple GO-EUC members. This project is shared publicly to allow others in the community to use the same infrastructure and configuration as the platform which allows you to reproduce our researches. Additionally, this project shows how an end-user computing environment can be built using modern technologies.

As GO-EUC is a community initiative any other contributions are welcome and can be done using a pull request.

## License
This work is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0)
 

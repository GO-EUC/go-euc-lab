## Flow
As mentioned earlier, the init script will provision your environment and consists of the following steps:

1. Collecting the settings.json file and converting it to an object
2. Collecting and downloading Hashicorp Terraform & Vault binaries via Evergreen (stealthpuppy.com)
3. AZ Login for creation of the SPN account
4. Switch to correct tennant and subscription based on the settings.json (or paramter)
5. Create SPN for deployment
6. Collect public IP dynamic or via config
6. Deployment storage backend account via Terraform
7. Create Azure DevOps project via Terraform



## TODO / Rember
AzureAD
Exporse the Vault container on DevOps with a firewall rule on public ip
Add LoadBalancer with PIP for container access
Add NSG to the PIP, Nic or Container


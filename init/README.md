The goal of the initialization script is to begin the deployment of the GO-EUC infrastructure. It will deploy the initial requirements depending on the platform and provision the project in your Azure DevOps environment. Once the project is provisioned, you will have the ability to start deploying the rest of the infrastructure.

## Getting started
In order to deploy this project, there are a couple of prerequisites.


  * Internet connection.
  * ISO creation tool (in the PATH variable) for Packer. Please refer to the [documentation](https://developer.hashicorp.com/packer/plugins/builders/vmware/iso#cd_files).
  * VMware ESX host version 7.x or higher.
  * SSH access enabled on the VMware host.
  * Azure DevOps environment.
  * Azure DevOps Personal Access Token (PAT).

The initialization script requires a JSON-based settings file with the following structure:

```json
{
    "domain_name": "go.euc",
    "ado_url": "https://dev.azure.com/orgname",
    "ado_agents": 5,
    "esx_hosts": [{
        "name": "infra-1",
        "user": "root",
        "ip": 11,
        "datastore": "datastore1",
        "network": "VMNet"
    },
    {
        "name": "infra-2",
        "user": "root",
        "ip": 12,
        "datastore": "datastore2",
        "network": "VMNet"
    }],
    "build": {
        "user": "gouser",
        "ip": 20
    },
    "docker": {
        "name": "dckr-1",
        "user": "gouser",
        "ip": 6
    },
    "network": {
        "cidr": "10.0.0.0/24",
        "gateway": 1,
        "dns": 1,
        "start": 10,
        "end": 200
    },
    "vcsa": {
        "name": "vcsa-1",
        "ip": 5
    },
    "software_store": "C:\\Software"
}
```
The following table will explain each indvidual setting.

| Setting | Type | Description |
| :------ | :--- | :---------- |
| domain_name | string | The domain name that is going to be created. It needs to be in the FQDN format. |
| ado_url | string | The Azure DevOps organization URL. |
| ado_agents | int | The number of Azure DevOps agents that will be created. |
| esx_hosts | list | A list with ESX hosts. |
| esx_hosts.name | string | The name of the ESX host. |
| esx_hosts.user | string | The username to access the ESX host. |
| esx_hosts.ip | int | The IP of the ESX host based on the CIDR. For example, 11 equals 10.0.0.11. |
| esx_hosts.datastore | string | The datastore name of the ESX host. |
| esx_hosts.network | string | The network adapter name of the ESX host. |
| build | obj | An object for the build machine information. |
| build.user | string | The local username for the build. |
| build.ip | int | The IP for the build machine based on the CIDR. For example, 20 equals 10.0.0.20. |
| docker | obj | An object for the docker machine information. |
| docker.name | string | The name for the docker machine. |
| docker.user | string | The username for the docker machine. |
| docker.ip | int | The IP for the docker machine based on the CIDR. For example, 6 equals 10.0.0.6. |
| network | obj | An object for the network information. |
| network.cidr | string | The network CIDR string. For example, 10.0.0.0/24. |
| network.gateway | int | The default network gateway based on CIDR. For example, 1 equals 10.0.0.1. |
| network.dns | int | The default DNS server based on CIDR. For example, 1 equals 10.0.0.1. |
| network.start | int | The starting range for the DHCP server based on CIDR. For example, 20 equals 10.0.0.20. |
| network.end | int | The end of the range for the DHCP server based on CIDR. For example, 200 equals 10.0.0.200. |
| vcsa | obj | An object for the VMware vCenter Appliance information. |
| vcsa.name | string | The name for the appliance. |
| vcsa.ip | int | The IP based on CIDR. For example, 5 equals 10.0.0.5. |
| software_store | string | The local location where all the software is stored. |

### ESX Hosts
As shown in the settings.json file, it is possible to add multiple ESX hosts. However, the first ESX host listed will be used to provision the main infrastructure.

### Azure DevOps
The init script will create a new project in your Azure DevOps environment and will not affect existing projects. The Personal Access Token (PAT) requires Read, Write, and Manage permissions on both "Project and Team" and "Agent Pools".

For more information about the PAT, please refer to the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows).

### Software Store
Unfortunately, many vendors hide their software behind a login page, making it impossible to automate the download process. Therefore, in order to deploy all components, the following software needs to be downloaded and structured as shown below.

```
├── Citrix
│   ├── CVAD
│   |   ├── 2203
│   |   |   ├── iso
├── VMware
│   ├── VCSA
│   |   ├── 2203
│   |   |   ├── iso
│   ├── Horizon
│   |   ├── 2203
│   |   |   ├── exe
│   |   |   ├── exe
├── Microsoft
|   ├── Server
|   |   ├── iso
|   ├── Desktop
|   |   ├── iso
```

During execution, all files will be uploaded to the Docker host and served via NGINX.

### Starting the init script
To start the deployment, the following parameters are required:

  * AdoPat in string format
  * ESXPassword in secure string format

You can create a secure string using the following example:

```powershell
$creds = Get-Credential
$securePassword = $creds.Password
```
or
```powershell
$securePassword = ConvertTo-SecureString -String "Myl33tP@ssw0rd!" -AsPlainText
```
> Please note that using the last example will be stored in the PowerShell history.

Start the init script as followed:
```powershell
.\init.ps1 -AdoPat "00112233445566778899" -ESXPassword $securePassword
```

## Flow
As mentioned earlier, the init script will provision your environment and consists of the following steps:

1. Collecting the settings.json file and converting it to an object
2. Installing required modules: Posh-SSH and Indented.Net.IP
3. Clearing any existing trusted SSH hosts
4. Calculating the network range based on CIDR
5. Collecting and downloading Hashicorp Terraform, Packer & Vault binaries via Evergreen (stealthpuppy.com)
6. Setting Packer requirements on the initial ESX host
7. Downloading OpenSSL to create a password for Ubuntu
8. Deploying Packer for the Ubuntu host
9. Starting the Ubuntu machine on the host
10. Creating Docker container for Postgres
11. Creating Docker container for Hashicorp Vault
12. Adding all secrets to the Vault
13. Deploying Azure DevOps project via Terraform
14. Creating Docker container for Azure DevOps Agents
15. Uploading software to the Ubuntu machine
16. Providing the Vault token, which must be saved in a secure location.

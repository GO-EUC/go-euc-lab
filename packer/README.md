This section will describe the requirements for the packer image deployments.

## Azure
TODO

## VMware
This partly is forked/based on the [packer-examples-for-vsphere](https://github.com/vmware-samples/packer-examples-for-vsphere/) repository.

The implementation has been adjusted to fit the GO-EUC use-case for the primary images only.

The following builds are included:

### Linux Distributions
  * Ubuntu Server 22.04 LTS (cloud-init)

### Microsoft Windows (Desktop only)
  * Microsoft Windows Server 2022 Standard
  * Microsoft Windows 11
  * Microsoft Windows 10

> **Note**
>
> - The Microsoft Windows 11 machine image requirement for trusted platform module (TPM) has been disabled by default.
>
> - All deployment has been configured using a static address which need to be configured in the pkvars files.

### Configuration

Generate a SHA-512 encrypted password for the build_password_encrypted using tools like mkpasswd.

Example: Ubuntu
```
ryan@Ryan-XPS:~$ mkpasswd -m sha-512
Password: **************
[password hash]
```

Generate a public key for the build_key for public key authentication.

Example: macOS and Linux.
```
ryan@Ryan-XPS:~$ ssh-keygen -t ecdsa -b 521 -C "code@go-euc.com"
Generating public/private ecdsa key pair.
Enter file in which to save the key (/home/ryan/.ssh/id_ecdsa): 
Enter passphrase (empty for no passphrase): **************
Enter same passphrase again: **************
Your identification has been saved in /home/ryan/.ssh/id_ecdsa
Your public key has been saved in /home/ryan/.ssh/id_ecdsa.pub
```
#### pkvars files

Example vpshere.pkvars.hcl:
```
vsphere_endpoint   = "10.2.0.5"
vsphere_username   = "administrator@vsphere.local"
vsphere_password   = "********"
vsphere_datacenter = "GO"
vsphere_cluster    = "Infra"
vsphere_datastore  = "datastore1"
vsphere_network    = "VM Network"
vsphere_folder     = "Infra"
```

Example ubuntu.pkrvars.hcl:
```
iso_datastore      = "datastore1"
iso_path           = "ISO"
iso_file           = "ubuntu-22.04.1-live-server-amd64.iso"
iso_checksum_type  = "sha256"
iso_checksum_value = "10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"

build_username           = "gouser"
build_password           = "********"
build_password_encrypted = "********"
build_key                = "********"

ansible_username = "goansible"
ansible_key      = "*******"

network_cidr    = "10.2.0.0/24"
network_address = 34
network_gateway = 1
network_dns     = 1
```

Example windows-11.pkrvars.hcl:
```
iso_datastore      = "datastore1"
iso_path           = "ISO/"
iso_file           = "en-us_windows_11_business_editions_version_22h2_updated_nov_2022_x64_dvd_7ed4b518.iso"
iso_checksum_type  = "sha256"
iso_checksum_value = "ba2e554995dcff429732894dd31e76503f6f9073aaa46d45443f55e602fb3ae4"

vm_boot_wait = "3s"

build_username     = "gouser"
build_password     = "*******"
build_organization = "GO-EUC"

network_cidr    = "10.2.0.0/24"
network_address = 33
network_gateway = 1
network_dns     = 1
```

## Nutanix
The Nutanix templates mirror the VMware layout and use the official [Packer Plugin for Nutanix](https://github.com/nutanix-cloud-native/packer-plugin-nutanix), which requires a Prism Central endpoint (see `init/nutanix/README.md` for the prerequisite).

The following builds are included:

### Microsoft Windows
  * Microsoft Windows Server 2019/2022/2025 Standard
  * Microsoft Windows 11 (secure boot with vTPM)

Each build boots a temporary VM from the operating system ISO plus the Nutanix VirtIO driver ISO (both registered in the Prism image library from the software store on first use), runs the unattended installation, and captures the disk as an image library entry. The image pipeline then publishes a Prism Element manifest with the image's `vm_disk_id` for Terraform.

Example windows-server-2022.pkrvars.hcl:
```
prism_central_endpoint         = "10.2.0.21"
prism_central_username         = "admin"
prism_central_password         = "********"
nutanix_cluster_uuid           = "0005f2f8-..."
nutanix_subnet_uuid            = "c1a2b3c4-..."
nutanix_storage_container_uuid = "d4e5f6a7-..."

iso_uri            = "http://10.2.0.6:8080/Microsoft/windows_server_2022.iso"
iso_checksum_type  = "sha256"
iso_checksum_value = "********"
virtio_iso_uri     = "http://10.2.0.6:8080/Nutanix/Nutanix-VirtIO-1.2.3.iso"

build_username     = "gouser"
build_password     = "*******"
build_organization = "GO-EUC"

network_cidr    = "10.2.0.0/24"
network_address = 20
network_gateway = 1
network_dns     = 1
```

Build command for Windows Server 2022 on Nutanix (run from the repository root so the provisioning scripts resolve):
```
packer init packer/nutanix/windows/server/2022
packer build -var-file="packer/nutanix/windows-server-2022.pkrvars.hcl" packer/nutanix/windows/server/2022
```

### Build commands

Build command for Ubuntu:
```
packer init packer/vmware/linux/ubuntu/22-04-lts/
packer build -var-file="packer/vmware/vsphere.pkrvars.hcl" -var-file="packer/vmware/ubuntu.pkrvars.hcl" packer/vmware/linux/ubuntu/22-04-lts
```

Build command for Windows 11:
```
packer init packer/vmware/windows/desktop/11
packer build -var-file="packer/vmware/vsphere.pkrvars.hcl" -var-file="packer/vmware/windows-11.pkrvars.hcl" packer/vmware/windows/desktop/11
```

## Credits
All credits to [Ryan Johnson](https://github.com/tenthirtyam) and the repro [contributors](https://github.com/vmware-samples/packer-examples-for-vsphere/graphs/contributors).
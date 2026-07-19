/*
    DESCRIPTION:
    Microsoft Windows Server 2019 variables using the Packer Builder for Nutanix (Prism Central).
*/

//  BLOCK: variable
//  Defines the input variables.

// Prism Central Credentials

variable "prism_central_endpoint" {
  type        = string
  description = "The fully qualified domain name or IP address of the Prism Central instance. (e.g. 'pc.lab.local')"
}

variable "prism_central_username" {
  type        = string
  description = "The username to login to the Prism Central instance."
  sensitive   = true
}

variable "prism_central_password" {
  type        = string
  description = "The password for the login to the Prism Central instance."
  sensitive   = true
}

variable "prism_central_port" {
  type        = number
  description = "The port used to connect to the Prism Central instance."
  default     = 9440
}

variable "prism_central_insecure" {
  type        = bool
  description = "Do not validate the Prism Central TLS certificate."
  default     = true
}

// Nutanix Settings

variable "nutanix_cluster_uuid" {
  type        = string
  description = "The UUID of the target Nutanix cluster registered in Prism Central."
}

variable "nutanix_subnet_uuid" {
  type        = string
  description = "The UUID of the target cluster subnet."
}

variable "nutanix_storage_container_uuid" {
  type        = string
  description = "The UUID of the storage container for the temporary VM disk."
}

// Installer Settings

variable "vm_inst_os_language" {
  type        = string
  description = "The installation operating system lanugage."
  default     = "en-US"
}

variable "vm_inst_os_keyboard" {
  type        = string
  description = "The installation operating system keyboard input."
  default     = "en-US"
}

variable "vm_inst_os_image_standard_desktop" {
  type        = string
  description = "The installation operating system image input for Microsoft Windwows Standard."
  default     = "Windows Server 2019 SERVERSTANDARD"
}

variable "vm_inst_os_kms_key_standard" {
  type        = string
  description = "The installation operating system KMS key input for Microsoft Windwows Standard edition."
  default     = "N69G4-B89J2-4G8F4-WWYCC-J464C"
}

// Virtual Machine Settings

variable "vm_guest_os_language" {
  type        = string
  description = "The guest operating system lanugage."
  default     = "en-US"
}

variable "vm_guest_os_keyboard" {
  type        = string
  description = "The guest operating system keyboard input."
  default     = "en-US"
}

variable "vm_guest_os_timezone" {
  type        = string
  description = "The guest operating system timezone."
  default     = "CET"
}

variable "vm_guest_os_family" {
  type        = string
  description = "The guest operating system family. Used for naming. (e.g.'windows')"
  default     = "windows"
}

variable "vm_guest_os_name" {
  type        = string
  description = "The guest operating system name. Used for naming. (e.g. 'server')"
  default     = "server"
}

variable "vm_guest_os_version" {
  type        = string
  description = "The guest operating system version. Used for naming. (e.g. '2019')"
  default     = "2019"
}

variable "vm_guest_os_edition_standard" {
  type        = string
  description = "The guest operating system edition. Used for naming. (e.g. 'standard')"
  default     = "standard"
}

variable "vm_cpu_sockets" {
  type        = number
  description = "The number of virtual CPUs sockets. (e.g. '2')"
  default     = 2
}

variable "vm_cpu_cores" {
  type        = number
  description = "The number of virtual CPUs cores per socket. (e.g. '1')"
  default     = 1
}

variable "vm_mem_size" {
  type        = number
  description = "The size for the virtual memory in MB. (e.g. '4096')"
  default     = 4096
}

variable "vm_disk_size" {
  type        = number
  description = "The size for the virtual disk in GB. (e.g. '100')"
  default     = 100
}

// Removable Media Settings

variable "iso_uri" {
  type        = string
  description = "The URI of the guest operating system ISO. Downloaded into the Prism image library on first use. (e.g. 'http://10.0.0.6:8080/Microsoft/windows_server_2022.iso')"
}

variable "iso_checksum_type" {
  type        = string
  description = "The checksum type of the guest operating system ISO. (e.g. 'sha256')"
  default     = null
}

variable "iso_checksum_value" {
  type        = string
  description = "The checksum value of the guest operating system ISO."
  default     = null
}

variable "virtio_iso_uri" {
  type        = string
  description = "The URI of the Nutanix VirtIO driver ISO. Downloaded into the Prism image library on first use. (e.g. 'http://10.0.0.6:8080/Nutanix/Nutanix-VirtIO-1.2.3.iso')"
}

variable "virtio_driver_path" {
  type        = string
  description = "The driver folder on the VirtIO ISO for this operating system. (e.g. 'E:\\Windows Server 2019\\x64')"
  default     = "E:\\Windows Server 2019\\x64"
}

// Boot Settings

variable "vm_boot_type" {
  type        = string
  description = "The boot type of the temporary VM. ('legacy', 'uefi' or 'secure_boot')"
  default     = "uefi"
}

variable "vm_boot_priority" {
  type        = string
  description = "The boot device priority of the temporary VM. ('cdrom' or 'disk')"
  default     = "cdrom"
}

variable "vm_boot_wait" {
  type        = string
  description = "The time to wait before typing the boot command."
  default     = "2s"
}

variable "vm_boot_command" {
  type        = list(string)
  description = "The virtual machine boot command to pass the 'press any key' prompt."
  default     = ["<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><enter>"]
}

variable "vm_shutdown_command" {
  type        = string
  description = "Command(s) for guest operating system shutdown."
  default     = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
}

variable "common_shutdown_timeout" {
  type        = string
  description = "Time to wait for guest operating system shutdown."
  default     = "15m"
}

// Communicator Settings and Credentials

variable "build_username" {
  type        = string
  description = "The username to login to the guest operating system. (e.g. 'rainpole')"
  sensitive   = true
}

variable "build_organization" {
  type        = string
  description = "The build organization. (e.g. 'GO-EUC')"
  sensitive   = true
}

variable "build_password" {
  type        = string
  description = "The password to login to the guest operating system."
  sensitive   = true
}

variable "communicator_port" {
  type        = number
  description = "The port for the communicator protocol."
  default     = 5985
}

variable "communicator_timeout" {
  type        = string
  description = "The timeout for the communicator protocol."
  default     = "12h"
}

// Provisioner Settings

variable "scripts" {
  type        = list(string)
  description = "A list of scripts and their relative paths to transfer and run."
  default = [
    "packer/nutanix/scripts/windows/windows-ansible.ps1"
  ]
}

variable "inline" {
  type        = list(string)
  description = "A list of commands to run."
  default = [
    "Get-EventLog -LogName * | ForEach { Clear-EventLog -LogName $_.Log }"
  ]
}

// Static Network Address

variable "network_cidr" {
  type        = string
  description = "Default network cidr, example: 10.2.0.0/24"
}

variable "network_address" {
  type        = number
  description = "Network address of the template machine, example: 31, will be 10.2.0.31/24"
}

variable "network_gateway" {
  type        = number
  description = "Default network gateway address, example: 1, will be 10.2.0.1"
}

variable "network_dns" {
  type        = number
  description = "Default network DNS address, example: 1, will be 10.2.0.1"
}

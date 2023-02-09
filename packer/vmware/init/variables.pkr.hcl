variable "iso_url" {
    type = string
    default = "https://releases.ubuntu.com/22.04.1/ubuntu-22.04.1-live-server-amd64.iso"
}

variable "iso_checksum" {
    type = string
    default = "sha256:10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"
}

variable "esx_host" {
    type = string
}

variable "esx_username" {
    type = string
}

variable "esx_password" {
    type = string
    sensitive = true
}

variable "esx_vnc_over_websocket" {
    type = bool
    default = true
}

variable "esx_insecure_connection" {
    type = bool
    default = true
}

variable "network_cidr" {
    type  = string
}

variable "network_address" {
    type = number
    default = 3
}

variable "network_gateway" {
    type = number
    default = 1
}

variable "network_dns" {
    type = number
    default = 1
}

# VM variables
variable "vm_name" {
    type = string
    default = "docker-1"
}

variable "vm_guest_os_type" {
    type = string
    default = "ubuntu64Guest"
}

variable "vm_guest_os_language" {
    type = string
    default = "en_US"
}

variable "vm_guest_os_keyboard" {
    type = string
    default = "us"
}

variable "vm_guest_os_timezone" {
    type = string
    default = "UTC"
}

variable "vm_version" {
    type = number
    default = 19
}

variable "vm_cpus" {
    type = number
    default = 2
}

variable "vm_memory" {
    type = number
    default = 2048
}

variable "vm_disk_datastore" {
    type = string
}

variable "vm_disk_size" {
    type = number
    default = 40960
}

variable "vm_disk_type_id" {
    type = string
    default = "thin"
}

variable "vm_network_name" {
    type = string
    default = "VM Network"
}

variable "vm_network_adapter_type" {
    type = string
    default = "vmxnet3"
}

variable "build_username" {
    type = string
    default = "gouser"
}

variable "build_password" {
    type = string
    sensitive = true
}

variable "build_password_encrypted" {
    type = string
    sensitive = true
}


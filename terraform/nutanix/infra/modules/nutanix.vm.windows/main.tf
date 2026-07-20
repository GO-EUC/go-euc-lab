# null_resource is used instead of terraform_data because the DevOps agent
# image ships Terraform 1.3, which predates terraform_data (added in 1.4).
# Everything the destroy provisioner needs is stored in triggers, since
# destroy-time provisioners may only reference self. A change to any trigger
# (including the sysprep content hash) forces the VM to be recreated.
locals {
  sysprep = [
    for i in range(var.vm_count) :
    templatefile("${path.module}/sysprep.xml.tftpl", {
      computer_name  = "${var.vm_name}-${i + 1}"
      ip_address     = var.network_addresses[i]
      prefix         = var.network_prefix
      gateway        = var.network_gateway
      dns            = var.network_dns[0]
      admin_password = var.local_admin_password
    })
  ]
}

resource "null_resource" "vm" {
  count = var.vm_count

  triggers = {
    name           = "${var.vm_name}-${count.index + 1}"
    ip_address     = var.network_addresses[count.index]
    image_uuid     = var.image_uuid
    prism_endpoint = var.prism_endpoint
    prism_username = var.prism_username
    prism_password = var.prism_password
    prism_insecure = var.prism_insecure
    cluster_uuid   = var.cluster_uuid
    subnet_uuid    = var.subnet_uuid
    adapter_path   = var.adapter_path
    vm_cpu         = var.vm_cpu
    vm_memory      = var.vm_memory
    vm_disk_size   = var.vm_disk_size
    sysprep_path   = "${path.module}/sysprep-${count.index}.xml"
    sysprep_hash   = sha256(local.sysprep[count.index])
  }

  # The sysprep file is written here, immediately before the adapter needs it,
  # rather than by a separate resource: pipeline workspaces are cleaned between
  # runs (and applies can land on any agent), so a file produced by an earlier
  # apply cannot be assumed to still exist.
  provisioner "local-exec" {
    interpreter = ["pwsh", "-Command"]
    environment = {
      PRISM_PASSWORD = self.triggers.prism_password
    }
    command = <<-EOT
      @'
${local.sysprep[count.index]}
'@ | Set-Content -Path '${self.triggers.sysprep_path}' -Encoding utf8
      $secure = ConvertTo-SecureString $env:PRISM_PASSWORD -AsPlainText -Force
      & '${self.triggers.adapter_path}' -Action CreateVm -Endpoint '${self.triggers.prism_endpoint}' -Username '${self.triggers.prism_username}' -Password $secure -ClusterUuid '${self.triggers.cluster_uuid}' -SubnetUuid '${self.triggers.subnet_uuid}' -ImageUuid '${self.triggers.image_uuid}' -Name '${self.triggers.name}' -Cpu ${self.triggers.vm_cpu} -MemoryMiB ${self.triggers.vm_memory} -DiskSizeGiB ${self.triggers.vm_disk_size} -SysprepUnattendPath '${self.triggers.sysprep_path}' -SkipCertificateCheck:$('${self.triggers.prism_insecure}' -eq 'true')
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["pwsh", "-Command"]
    environment = {
      PRISM_PASSWORD = self.triggers.prism_password
    }
    command = <<-EOT
      $secure = ConvertTo-SecureString $env:PRISM_PASSWORD -AsPlainText -Force
      & '${self.triggers.adapter_path}' -Action DeleteVm -Endpoint '${self.triggers.prism_endpoint}' -Username '${self.triggers.prism_username}' -Password $secure -Name '${self.triggers.name}' -SkipCertificateCheck:$('${self.triggers.prism_insecure}' -eq 'true')
    EOT
  }
}

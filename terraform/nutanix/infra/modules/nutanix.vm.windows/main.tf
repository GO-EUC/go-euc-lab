resource "terraform_data" "vm" {
  count      = var.vm_count
  depends_on = [terraform_data.sysprep]

  input = {
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
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-Command"]
    environment = {
      PRISM_PASSWORD = self.input.prism_password
    }
    command = <<-EOT
      $secure = ConvertTo-SecureString $env:PRISM_PASSWORD -AsPlainText -Force
      & '${self.input.adapter_path}' -Action CreateVm -Endpoint '${self.input.prism_endpoint}' -Username '${self.input.prism_username}' -Password $secure -ClusterUuid '${self.input.cluster_uuid}' -SubnetUuid '${self.input.subnet_uuid}' -ImageUuid '${self.input.image_uuid}' -Name '${self.input.name}' -Cpu ${self.input.vm_cpu} -MemoryMiB ${self.input.vm_memory} -DiskSizeGiB ${self.input.vm_disk_size} -SysprepUnattendPath '${self.input.sysprep_path}' -SkipCertificateCheck:${self.input.prism_insecure}
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["pwsh", "-Command"]
    environment = {
      PRISM_PASSWORD = self.input.prism_password
    }
    command = <<-EOT
      $secure = ConvertTo-SecureString $env:PRISM_PASSWORD -AsPlainText -Force
      & '${self.input.adapter_path}' -Action DeleteVm -Endpoint '${self.input.prism_endpoint}' -Username '${self.input.prism_username}' -Password $secure -Name '${self.input.name}' -SkipCertificateCheck:${self.input.prism_insecure}
    EOT
  }

  lifecycle {
    replace_triggered_by = [terraform_data.sysprep]
  }
}

resource "terraform_data" "sysprep" {
  count = var.vm_count

  input = sha256(templatefile("${path.module}/sysprep.xml.tftpl", {
    computer_name  = "${var.vm_name}-${count.index + 1}"
    ip_address     = var.network_addresses[count.index]
    prefix         = var.network_prefix
    gateway        = var.network_gateway
    dns            = var.network_dns[0]
    admin_password = var.local_admin_password
  }))

  provisioner "local-exec" {
    interpreter = ["pwsh", "-Command"]
    command = <<-EOT
      @'
${templatefile("${path.module}/sysprep.xml.tftpl", {
    computer_name  = "${var.vm_name}-${count.index + 1}"
    ip_address     = var.network_addresses[count.index]
    prefix         = var.network_prefix
    gateway        = var.network_gateway
    dns            = var.network_dns[0]
    admin_password = var.local_admin_password
})}
'@ | Set-Content -Path '${path.module}/sysprep-${count.index}.xml' -Encoding utf8
    EOT
}
}

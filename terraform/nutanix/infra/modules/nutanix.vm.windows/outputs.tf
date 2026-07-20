output "vm_info" {
  # The VM addresses derive from the network CIDR stored in Vault, so they
  # carry Terraform's sensitive mark. Names and IPs are not secrets (Ansible
  # needs them in its inventory), so strip the mark the same way the VMware
  # infra outputs do.
  value = nonsensitive(formatlist(
    "%s ansible_host=%s",
    [for i in range(var.vm_count) : "${var.vm_name}-${i + 1}"],
    var.network_addresses
  ))
  depends_on = [null_resource.vm]
}

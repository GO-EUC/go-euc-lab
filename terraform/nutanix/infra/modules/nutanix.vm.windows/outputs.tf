output "vm_info" {
  # The VM addresses derive from the network CIDR stored in Vault, so they
  # carry Terraform's sensitive mark. Names and IPs are not secrets (Ansible
  # needs them in its inventory), so strip the mark the same way the VMware
  # infra outputs do.
  # formatlist of two empty lists is not sensitive, and nonsensitive() errors
  # when the value is already unmarked (bot_count = 0).
  value = var.vm_count == 0 ? [] : nonsensitive(formatlist(
    "%s ansible_host=%s",
    [for i in range(var.vm_count) : "${var.vm_name}-${i + 1}"],
    var.network_addresses
  ))
  depends_on = [nutanix_virtual_machine.vm]
}

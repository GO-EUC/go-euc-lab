output "vm_info" {
  # Built from the input variables rather than null_resource.vm triggers: the
  # triggers map contains the (sensitive) Prism password, and Terraform
  # propagates that sensitivity to the whole map, which would force every root
  # output consuming this value to be marked sensitive.
  value = [
    for i in range(var.vm_count) :
    "${var.vm_name}-${i + 1} ansible_host=${var.network_addresses[i]}"
  ]
  depends_on = [null_resource.vm]
}

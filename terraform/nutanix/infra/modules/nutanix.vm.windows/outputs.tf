output "vm_info" {
  value = formatlist("%s ansible_host=%s", terraform_data.vm[*].input.name, terraform_data.vm[*].input.ip_address)
}

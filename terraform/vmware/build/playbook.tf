resource "ansible_playbook" "playbook" {
  playbook   = "${var.root_path}/${var.ansible_playbook}"
  name       = module.build.vm_info
  replayable = true

  extra_vars = {
    vault_addr  = var.vault_address
    vault_token = var.vault_token
    delivery    = var.delivery
  }
}
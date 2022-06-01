output "avd_registration_token" {
  description = "AVD Registration token generated during Terraform apply"
  value       = azurerm_virtual_desktop_host_pool_registration_info.token.token
}
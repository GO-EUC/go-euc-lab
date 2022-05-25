resource "azurerm_virtual_machine_extension" "domainjoinext" {
  count                = var.sessionhost_amount
  name                 = "join-domain"
  virtual_machine_id   = azurerm_windows_virtual_machine.sessionhostvms[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.0"
  depends_on           = [azurerm_windows_virtual_machine.sessionhostvms]

  settings = <<SETTINGS
    {
        "Name": "${var.AD_domain}",
        "OUPath": "${var.AD_oupath}",
        "User": "${var.AD_joinuser}",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
        "Password": "${var.AD_joinpassword}"
    }
PROTECTED_SETTINGS
}
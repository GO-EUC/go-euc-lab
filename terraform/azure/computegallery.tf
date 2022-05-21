resource "azurerm_shared_image_gallery" "azurecomputegallery" {
  name                = "gal_packer_${local.environment_abbreviations[terraform.workspace]}"
  resource_group_name = azurerm_resource_group.EUCWorkers.name
  location            = azurerm_resource_group.EUCWorkers.location
  description         = "Shared images and things."
}

resource "azurerm_shared_image" "image_avd" {
  name                   = "Windows10-21h2-avd"
  gallery_name           = azurerm_shared_image_gallery.azurecomputegallery.name
  resource_group_name    = azurerm_resource_group.EUCWorkers.name
  location               = azurerm_resource_group.EUCWorkers.location
  os_type                = "Windows"
  specialized            = false
  hyper_v_generation     = "V2"
  trusted_launch_enabled = false

  identifier {
    publisher = "microsoftwindowsdesktop"
    offer     = "Windows-10"
    sku       = "win10-21h2-avd-g2"
  }
}

resource "azurerm_shared_image" "image_citrix" {
  name                   = "Windows10-21h2-citrix"
  gallery_name           = azurerm_shared_image_gallery.azurecomputegallery.name
  resource_group_name    = azurerm_resource_group.EUCWorkers.name
  location               = azurerm_resource_group.EUCWorkers.location
  os_type                = "Windows"
  specialized            = false
  hyper_v_generation     = "V2"
  trusted_launch_enabled = false

  identifier {
    publisher = "microsoftwindowsdesktop"
    offer     = "Windows-10"
    sku       = "win10-21h2-citrix-g2"
  }
}
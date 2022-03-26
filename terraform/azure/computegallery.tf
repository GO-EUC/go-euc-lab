resource "azurerm_shared_image_gallery" "azurecomputegallery" {
  name                = "gal_packer_${local.environment_abbreviations[terraform.workspace]}"
  resource_group_name = azurerm_resource_group.EUCWorkers.name
  location            = azurerm_resource_group.EUCWorkers.location
  description         = "Shared images and things."
}

resource "azurerm_shared_image" "ws2019" {
  name                   = "img-ws2019"
  gallery_name           = azurerm_shared_image_gallery.azurecomputegallery.name
  resource_group_name    = azurerm_resource_group.EUCWorkers.name
  location               = azurerm_resource_group.EUCWorkers.location
  os_type                = "Windows"
  specialized            = false
  hyper_v_generation     = "V2"
  trusted_launch_enabled = true

  identifier {
    publisher = "GO-EUC"
    offer     = "WindowsServerTrustLaunch"
    sku       = "2019"
  }
}

resource "azurerm_shared_image" "ws2022" {
  name                   = "img-ws2022"
  gallery_name           = azurerm_shared_image_gallery.azurecomputegallery.name
  resource_group_name    = azurerm_resource_group.EUCWorkers.name
  location               = azurerm_resource_group.EUCWorkers.location
  os_type                = "Windows"
  specialized            = false
  hyper_v_generation     = "V2"
  trusted_launch_enabled = true

  identifier {
    publisher = "GO-EUC"
    offer     = "WindowsServerTrustLaunch"
    sku       = "2022"
  }
}

resource "azurerm_shared_image" "w1021h2-avd" {
  name                   = "img-w1021h2"
  gallery_name           = azurerm_shared_image_gallery.azurecomputegallery.name
  resource_group_name    = azurerm_resource_group.EUCWorkers.name
  location               = azurerm_resource_group.EUCWorkers.location
  os_type                = "Windows"
  specialized            = false
  hyper_v_generation     = "V2"
  trusted_launch_enabled = true

  identifier {
    publisher = "GO-EUC"
    offer     = "WindowsAVD"
    sku       = "W1021H2"
  }
}

resource "azurerm_shared_image" "w1021h1-avd" {
  name                   = "img-w1021h1"
  gallery_name           = azurerm_shared_image_gallery.azurecomputegallery.name
  resource_group_name    = azurerm_resource_group.EUCWorkers.name
  location               = azurerm_resource_group.EUCWorkers.location
  os_type                = "Windows"
  specialized            = false
  hyper_v_generation     = "V2"
  trusted_launch_enabled = true

  identifier {
    publisher = "GO-EUC"
    offer     = "WindowsAVD"
    sku       = "W1021H1"
  }
}

resource "azurerm_shared_image" "w1020h2-avd" {
  name                   = "img-w1021h2"
  gallery_name           = azurerm_shared_image_gallery.azurecomputegallery.name
  resource_group_name    = azurerm_resource_group.EUCWorkers.name
  location               = azurerm_resource_group.EUCWorkers.location
  os_type                = "Windows"
  specialized            = false
  hyper_v_generation     = "V2"
  trusted_launch_enabled = true

  identifier {
    publisher = "GO-EUC"
    offer     = "WindowsAVD"
    sku       = "W1020H2"
  }
}

resource "azurerm_shared_image" "w101909-avd" {
  name                   = "img-w101909"
  gallery_name           = azurerm_shared_image_gallery.azurecomputegallery.name
  resource_group_name    = azurerm_resource_group.EUCWorkers.name
  location               = azurerm_resource_group.EUCWorkers.location
  os_type                = "Windows"
  specialized            = false
  hyper_v_generation     = "V2"
  trusted_launch_enabled = true

  identifier {
    publisher = "GO-EUC"
    offer     = "WindowsAVD"
    sku       = "W101909"
  }
}


resource "azurerm_shared_image" "w1121h2" {
  name                   = "img-w1121h2"
  gallery_name           = azurerm_shared_image_gallery.azurecomputegallery.name
  resource_group_name    = azurerm_resource_group.EUCWorkers.name
  location               = azurerm_resource_group.EUCWorkers.location
  os_type                = "Windows"
  specialized            = false
  hyper_v_generation     = "V2"
  trusted_launch_enabled = true

  identifier {
    publisher = "GO-EUC"
    offer     = "WindowsAVD"
    sku       = "W1121H2"
  }
}
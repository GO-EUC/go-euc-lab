#####
# Add DNS Name Server
#####
resource "citrixadc_dnsnameserver" "finish_dnsnameserver" {
    dnsvservername = var.adc-finish.dnsvservername
    type           = var.adc-finish.dnsvservertype
}

#####
# Save config
#####
resource "citrixadc_nsconfig_save" "finish_save" {
  all        = true
  timestamp  = timestamp()

  depends_on = [
      citrixadc_dnsnameserver.finish_dnsnameserver
  ]
}
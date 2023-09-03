locals {
  filelocation = "/nsconfig/license"
}

#####
# Add License
#####
resource "citrixadc_systemfile" "license_upload" {
    filename     = var.adc-license.filename
    filelocation = local.filelocation
    filecontent  = var.adc-license.filecontent
}

#####
# Save Configuration
#####
resource "citrixadc_nsconfig_save" "license_save" {
    all        = true
    timestamp  = timestamp()

    depends_on = [
        citrixadc_systemfile.license_upload
    ]
}

#####
# Reboot for license application
#####
resource "citrixadc_rebooter" "license_reboot" {
    timestamp            = timestamp()
    warm                 = true
    wait_until_reachable = false

    depends_on           = [
        citrixadc_nsconfig_save.license_save
    ]
}

#####
# Wait a few seconds
#####
resource "time_sleep" "license_wait_a_few_seconds" {

  create_duration = "90s"

  depends_on = [
    citrixadc_rebooter.license_reboot
  ]

}
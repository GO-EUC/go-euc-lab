#####
# Reset password
#####
resource "citrixadc_password_resetter" "pw_password_reset" {
  username     = var.adc-base.username
  password     = var.adc-base.oldpassword
  new_password = var.adc-base.password
}

#####
# Wait a few seconds
#####
resource "time_sleep" "pw_wait_a_few_seconds" {
  create_duration = "15s"

  depends_on = [
    citrixadc_password_resetter.pw_password_reset
  ]
}

#####
# Save config
#####
resource "citrixadc_nsconfig_save" "pw_save" {    
    all       = true
    timestamp = timestamp()

  depends_on = [
    time_sleep.pw_wait_a_few_seconds
  ]
}

#####
# Wait a few seconds
#####
resource "time_sleep" "pw_wait_a_few_seconds_last" {
  create_duration = "15s"

  depends_on = [
    citrixadc_nsconfig_save.pw_save
  ]
}
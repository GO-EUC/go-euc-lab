#####
# Reset password
#####

resource "citrixadc_password_resetter" "tf_resetter" {
    username        = var.adc-base-username
    password        = var.adc-base-password
    new_password    = var.adc-base-newpassword
}
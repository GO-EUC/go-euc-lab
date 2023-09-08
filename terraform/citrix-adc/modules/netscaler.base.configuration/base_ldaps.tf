# Define the ldaps action, by default set to loadbalance via the data interface as best practice
# Don't forget to add basedn etc, in example it's omitted to prevent errors
# https://registry.terraform.io/providers/citrix/citrixadc/latest/docs/resources/authenticationldapaction
resource "citrixadc_authenticationldapaction" "auth_authenticationldapaction" {
  name          = var.auth_ldaps.action_name
  serverip      = var.virtual_servers.lb_ldaps.ipv46
  serverport    = 636
  sectype = var.auth_ldaps.sectype
  authtimeout   = var.auth_ldaps.authtimeout
  ldaploginname = var.auth_ldaps.ldaploginname
  ldapbase = var.auth_ldaps.ldapbase
  ldapbinddn = var.auth_ldaps.ldapbinddn
  ldapbinddnpassword = var.auth_ldaps.ldapbinddnpassword
}

# Define the authentication policy rules for LDAP, default is filter all to allow ('true')
resource "citrixadc_authenticationpolicy" "auth_authpolicy" {
  name   = var.auth_ldaps.policy_name
  rule   = var.auth_ldaps.policy_expression
  action = var.auth_ldaps.action_name

  depends_on = [citrixadc_authenticationldapaction.auth_authenticationldapaction]
}

# Bind the auth policy globally for management authentication
resource "citrixadc_systemglobal_authenticationldappolicy_binding" "tf_bind" {
  policyname     =  citrixadc_authenticationpolicy.auth_authpolicy.name
  priority       = 88
  feature        = "SYSTEM"

  depends_on = [citrixadc_authenticationpolicy.auth_authpolicy]
}





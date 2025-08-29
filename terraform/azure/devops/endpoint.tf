data "azurerm_subscription" "current" {
}

data "azuread_application" "app" {
  client_id = var.azure_client_id
}

data "azuread_service_principal" "app" {
  client_id = data.azuread_application.app.client_id
}

resource "time_rotating" "rotation" {
  rotation_months = 1
}

resource "azuread_application_password" "secret" {
  application_id = data.azuread_application.app.id
  display_name   = lower("${var.project_name}-azure-devops")
  end_date       = timeadd(timestamp(), "2160h")

  rotate_when_changed = {
    rotation = time_rotating.rotation.id
  }

  lifecycle {
    ignore_changes = [
      end_date
    ]
  }
}

resource "azuredevops_serviceendpoint_azurerm" "azure" {
  project_id                             = azuredevops_project.project.id
  service_endpoint_name                  = "AzureRM"
  description                            = "Managed by Terraform"
  service_endpoint_authentication_scheme = "ServicePrincipal"
  credentials {
    serviceprincipalid  = var.azure_client_id
    serviceprincipalkey = azuread_application_password.secret.value
  }
  azurerm_spn_tenantid      = var.azure_tenant_id
  azurerm_subscription_id   = var.azure_subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name
}

resource "azuredevops_serviceendpoint_github" "github" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = "GitHub"

  auth_personal {
    personal_access_token = var.github_pat
  }
}
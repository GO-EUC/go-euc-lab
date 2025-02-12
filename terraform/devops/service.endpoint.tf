resource "azuredevops_serviceendpoint_github" "github" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = "GitHub"

  auth_personal {
    personal_access_token = var.github_pat
  }
}
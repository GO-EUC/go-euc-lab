resource "azuredevops_build_definition" "infra" {
  project_id = azuredevops_project.project.id
  name       = "Lab Deployment Pipeline"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org}/${var.github_repo}"
    branch_name           = var.github_branch
    yml_path              = ".devops/pipelines/azure/infra.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }
}

resource "azuredevops_build_definition" "image" {
  project_id = azuredevops_project.project.id
  name       = "Image Deployment Pipeline"

  ci_trigger {
    use_yaml = false
  }
  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org}/${var.github_repo}"
    branch_name           = var.github_branch
    yml_path              = ".devops/pipelines/azure/image.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }
}

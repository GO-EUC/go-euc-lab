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
    yml_path              = ".devops/pipelines/vmware/infra.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }
  variable {
    name  = "pipeline_id"
    value = azuredevops_build_definition.image.id
  }

  variable {
    name  = "project_id"
    value = azuredevops_project.project.id
  }

  variable_groups = [
    azuredevops_variable_group.lab.id
  ]
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
    yml_path              = ".devops/pipelines/vmware/image.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  variable_groups = [
    azuredevops_variable_group.lab.id
  ]
}

resource "azuredevops_build_definition" "build" {
  project_id = azuredevops_project.project.id
  name       = "Build Deployment Pipeline"
  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org}/${var.github_repo}"
    branch_name           = var.github_branch
    yml_path              = ".devops/pipelines/vmware/build.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  variable {
    name  = "pipeline_id"
    value = azuredevops_build_definition.image.id
  }

  variable {
    name  = "project_id"
    value = azuredevops_project.project.id
  }

  variable_groups = [
    azuredevops_variable_group.lab.id
  ]
}

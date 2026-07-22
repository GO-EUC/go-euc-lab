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
  name       = "GitHub Build Deployment Pipeline"
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

resource "azuredevops_build_definition" "nutanix_infra" {
  project_id = azuredevops_project.project.id
  name       = "Nutanix CE - 2. Infra"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org}/${var.github_repo}"
    branch_name           = var.github_branch
    yml_path              = ".devops/pipelines/nutanix/infra.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  # Unlike the VMware path, no pipeline_id/project_id variables are needed:
  # the infra Terraform resolves images by name from the Prism Central image
  # library instead of downloading a manifest artifact from the image pipeline.
  variable_groups = [azuredevops_variable_group.lab.id]
}

resource "azuredevops_build_definition" "nutanix_image" {
  project_id = azuredevops_project.project.id
  name       = "Nutanix CE - 1. Images"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org}/${var.github_repo}"
    branch_name           = var.github_branch
    yml_path              = ".devops/pipelines/nutanix/image.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  variable_groups = [azuredevops_variable_group.lab.id]
}

# Utility pipeline: manually start or remove the temporary build DHCP
# container on the control-plane VM (the image pipeline manages it
# automatically during its own runs).
resource "azuredevops_build_definition" "nutanix_dhcp" {
  project_id = azuredevops_project.project.id
  name       = "Nutanix CE - Build DHCP"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org}/${var.github_repo}"
    branch_name           = var.github_branch
    yml_path              = ".devops/pipelines/nutanix/dhcp.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  variable_groups = [azuredevops_variable_group.lab.id]
}

resource "azuredevops_build_definition" "nutanix_build" {
  project_id = azuredevops_project.project.id
  name       = "Nutanix CE - 3. Delivery"

  ci_trigger {
    use_yaml = false
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = "${var.github_org}/${var.github_repo}"
    branch_name           = var.github_branch
    yml_path              = ".devops/pipelines/nutanix/build.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github.id
  }

  variable {
    name  = "pipeline_id"
    value = azuredevops_build_definition.nutanix_image.id
  }

  variable {
    name  = "project_id"
    value = azuredevops_project.project.id
  }

  variable_groups = [azuredevops_variable_group.lab.id]
}

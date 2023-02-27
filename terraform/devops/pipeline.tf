resource "azuredevops_build_definition" "infra" {
    project_id = azuredevops_project.project.id
    name       = "Lab Deployment Pipeline"

    ci_trigger {
        use_yaml = false
    }

    repository {
        repo_type   = "TfsGit"
        repo_id     = azuredevops_git_repository.repo.id
        yml_path    = ".devops/pipelines/vmware/infra.yml"
    }

    variable {
        name = "pipeline_id"
        value = azuredevops_build_definition.image.id
    }

    variable {
        name = "project_id"
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
        repo_type   = "TfsGit"
        repo_id     = azuredevops_git_repository.repo.id
        yml_path    = ".devops/pipelines/vmware/image.yml"
    }

    variable_groups = [
        azuredevops_variable_group.lab.id
    ]
}

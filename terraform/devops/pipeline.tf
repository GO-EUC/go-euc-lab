resource "azuredevops_build_definition" "pipeline" {
    project_id = azuredevops_project.project.id
    name       = "Lab Deployment Pipeline"

    ci_trigger {
        use_yaml = false
    }

    repository {
        repo_type   = "TfsGit"
        repo_id     = azuredevops_git_repository.repo.id
        yml_path    = ".devops/pipelines/vmware.yml"
    }

    variable_groups = [
        azuredevops_variable_group.lab.id
    ]
}
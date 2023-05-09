resource "azuredevops_git_repository" "repo" {
    project_id = azuredevops_project.project.id
    name       = "Lab"
    default_branch = "refs/heads/main"
    initialization {
        init_type   = "Import"
        source_type = "Git"
        source_url  = "https://github.com/GO-EUC/go-euc-lab.git"
    }
    lifecycle {
        ignore_changes = [
            initialization,
        ]
    }
}

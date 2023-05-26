data "azuredevops_users" "svc" {
    subject_types = ["svc"]
    origin = "vsts"
    depends_on = [
        azuredevops_project.project
    ]
}

locals {
        build_service = [
        for x in data.azuredevops_users.svc.users :
        x
        if can(regex("${azuredevops_project.project.name} Build Service", x.display_name))
    ]
}

data "azuredevops_group" "administrators" {
    project_id = azuredevops_project.project.id
    name       = "Build Administrators"
}

resource "azuredevops_group_membership" "member" {
    group = data.azuredevops_group.administrators.descriptor
    
    members = local.build_service[*].descriptor
}
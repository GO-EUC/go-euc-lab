resource "azuredevops_variable_group" "lab" {
    project_id   = azuredevops_project.project.id
    name         = "Lab"
    description  = "The lab variable group containing the required variables"
    allow_access = true

    dynamic "variable" {
        for_each = var.ado_variables
        content {
            name = variable.value.name
            value = variable.value.value
            is_secret = variable.value.is_secret
        }
    }
}

resource "azuredevops_variable_group" "lab" {
    project_id   = azuredevops_project.project.id
    name         = "Lab"
    description  = "The lab variable group containing the required variables"
    allow_access = true

    dynamic "variable" {
        for_each = [for var in var.ado_variables : var if var.is_secret == true]
        content {
            name = variable.value.name
            secret_value = variable.value.value
            is_secret = variable.value.is_secret
        }
    }

    dynamic "variable" {
        for_each = [for var in var.ado_variables : var if var.is_secret == false]
        content {
            name = variable.value.name
            value = variable.value.value
            is_secret = variable.value.is_secret
        }
    }
}

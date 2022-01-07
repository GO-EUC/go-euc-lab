resource "azuredevops_agent_pool" "pool" {
  name           = "${var.devops_pool}-${local.environment_abbreviations[terraform.workspace]}"
  auto_provision = false
}

data "azuredevops_project" "project" {
  name = var.devops_project
}

resource "azuredevops_agent_queue" "queue" {
  project_id    = data.azuredevops_project.project.id
  agent_pool_id = azuredevops_agent_pool.pool.id
}

resource "azuredevops_resource_authorization" "auth" {
  project_id  = data.azuredevops_project.project.id
  resource_id = azuredevops_agent_queue.queue.id
  type        = "queue"
  authorized  = true
}
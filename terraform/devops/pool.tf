resource "azuredevops_agent_pool" "pool" {
    name           = "GO Pipelines"
    auto_provision = false
}

resource "azuredevops_agent_queue" "queue" {
    project_id    = azuredevops_project.project.id
    agent_pool_id = azuredevops_agent_pool.pool.id
}

resource "azuredevops_resource_authorization" "auth" {
    project_id  = azuredevops_project.project.id
    resource_id = azuredevops_agent_queue.queue.id
    type        = "queue"
    authorized  = true
}
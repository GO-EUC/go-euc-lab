resource "random_integer" "agent" {
  min = 10000
  max = 99999
}

resource "azurerm_container_group" "docker" {
  name = "cn-docker-${local.environment_abbreviations[terraform.workspace]}"

  location            = azurerm_resource_group.Docker.location
  resource_group_name = azurerm_resource_group.Docker.name

  ip_address_type    = "private"
  network_profile_id = azurerm_network_profile.docker.id
  os_type            = "Linux"

  container {
    name   = "azure-devops-agent"
    image  = "goeuc/ado-agent:latest"
    cpu    = "1"
    memory = "2"

    environment_variables = {
      AZP_URL        = "https://dev.azure.com/${var.devops_orgname}"
      AZP_TOKEN      = "${var.devops_token}"
      AZP_AGENT_NAME = "${local.environment_abbreviations[terraform.workspace]}-${random_integer.agent.result}"
      AZP_POOL       = azuredevops_agent_pool.pool.name
    }
  }

  container {
    name   = "go-euc-webserver"
    image  = "goeuc/webserver:latest"
    cpu    = "1"
    memory = "2"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}
resource "azuredevops_project" "project" {
  name               = "${var.devops_project} Project"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
  description        = "Managed by GO-EUC"
  features = {
    "testplans" = "disabled"
    "artifacts" = "disabled"
    "boards"    = "disabled"
  }
}

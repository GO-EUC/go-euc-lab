resource "azuredevops_project" "project" {
  name               = "GO-EUC Lab"
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

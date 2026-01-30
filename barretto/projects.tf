resource "tfe_project" "prj_long_name" {
  organization = local.organization_name
  name         = "A Really Long Name"
}

resource "tfe_project" "project1" {
  organization = local.organization_name
  name         = "project1"
}

resource "tfe_project" "helloworld" {
  organization = local.organization_name
  name         = "helloworld"
}

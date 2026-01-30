data "tfe_organization_membership" "owner" {
  organization = tfe_organization.org.id
  email        = var.owner_email
}

data "tfe_team" "owners" {
  organization = tfe_organization.org.id
  name         = "owners"
}

data "tfe_project" "default" {
  organization = local.organization_name
  name         = "Default Project"
}

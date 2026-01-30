# Create an organization
# NOTE: Once the organization is created you need to update the subscription
# to allow the creation of teams
# https://app.staging.terraform.io/app/admin/organizations/barretto-provider-made
resource "tfe_organization" "org" {
  name                                                    = local.organization_name
  email                                                   = var.owner_email
  allow_force_delete_workspaces                           = true
  assessments_enforced                                    = true
  cost_estimation_enabled                                 = true
  send_passing_statuses_for_untriggered_speculative_plans = true
}

# Organization Token
resource "tfe_organization_token" "org_token" {
  organization = tfe_organization.org.name
}

# Agent Pool
resource "tfe_agent_pool" "agent-pool" {
  name                = "barrett-pool"
  organization        = tfe_organization.org.name
  organization_scoped = true
}

# Additional user in organization
resource "tfe_organization_membership" "bclark1" {
  organization = tfe_organization.org.name
  email        = "bclark1@yahoo.com"
}

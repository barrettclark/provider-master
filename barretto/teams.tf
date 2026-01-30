module "k8s_team" {
  source = "./modules/team"

  organization_name = local.organization_name
  team_name         = "k8s"
  create_token      = true
  force_regenerate_token = true

  organization_access = {
    manage_membership       = true
    manage_modules          = true
    manage_policies         = true
    manage_policy_overrides = true
    manage_projects         = true
    manage_providers        = true
    manage_run_tasks        = true
    manage_vcs_settings     = true
    manage_workspaces       = true
    read_projects           = true
    read_workspaces         = true
  }
}

module "limited_team" {
  source = "./modules/team"

  organization_name = local.organization_name
  team_name         = "limited"
  organization_access = {}
}

# Team members stay at root level due to depends_on constraints
resource "tfe_team_member" "k8s_members" {
  team_id  = module.k8s_team.team_id
  username = tfe_organization_membership.bclark1.username

  depends_on = [tfe_organization_membership.bclark1]
}

resource "tfe_team_member" "limited_members" {
  team_id  = module.limited_team.team_id
  username = tfe_organization_membership.bclark1.username

  depends_on = [tfe_organization_membership.bclark1]
}

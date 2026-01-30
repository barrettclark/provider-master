resource "tfe_team" "k8s" {
  name         = "k8s"
  organization = local.organization_name
  organization_access {
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

resource "tfe_team" "limited" {
  name         = "limited"
  organization = local.organization_name
  organization_access {}
}

resource "tfe_team_member" "k8s_members" {
  team_id  = tfe_team.k8s.id
  username = tfe_organization_membership.bclark1.username

  depends_on = [tfe_organization_membership.bclark1]
}

resource "tfe_team_member" "limited_members" {
  team_id  = tfe_team.limited.id
  username = tfe_organization_membership.bclark1.username

  depends_on = [tfe_organization_membership.bclark1]
}

resource "tfe_team_token" "k8s_token" {
  team_id          = tfe_team.k8s.id
  force_regenerate = true
}

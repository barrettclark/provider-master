terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.48.0"
    }
  }
}

resource "tfe_team" "team" {
  name         = var.team_name
  organization = var.organization_name

  dynamic "organization_access" {
    for_each = var.organization_access != null ? [var.organization_access] : []
    content {
      manage_membership       = try(organization_access.value.manage_membership, false)
      manage_modules          = try(organization_access.value.manage_modules, false)
      manage_policies         = try(organization_access.value.manage_policies, false)
      manage_policy_overrides = try(organization_access.value.manage_policy_overrides, false)
      manage_projects         = try(organization_access.value.manage_projects, false)
      manage_providers        = try(organization_access.value.manage_providers, false)
      manage_run_tasks        = try(organization_access.value.manage_run_tasks, false)
      manage_vcs_settings     = try(organization_access.value.manage_vcs_settings, false)
      manage_workspaces       = try(organization_access.value.manage_workspaces, false)
      read_projects           = try(organization_access.value.read_projects, false)
      read_workspaces         = try(organization_access.value.read_workspaces, false)
    }
  }
}

resource "tfe_team_token" "token" {
  count = var.create_token ? 1 : 0

  team_id          = tfe_team.team.id
  force_regenerate = var.force_regenerate_token
}

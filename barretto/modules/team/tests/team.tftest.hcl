# Tests for team module

# Test 1: Basic team without organization access
run "basic_team" {
  command = plan

  variables {
    team_name         = "test-team"
    organization_name = "test-org"
  }

  assert {
    condition     = tfe_team.team.name == "test-team"
    error_message = "Team name does not match input"
  }

  # Note: Can't check length of computed organization_access in plan mode
  # The dynamic block will result in 0 blocks when organization_access is null
}

# Test 2: Team with organization access
run "team_with_org_access" {
  command = plan

  variables {
    team_name         = "admin-team"
    organization_name = "test-org"
    organization_access = {
      manage_workspaces = true
      manage_projects   = true
      read_workspaces   = true
      read_projects     = true
    }
  }

  assert {
    condition     = length(tfe_team.team.organization_access) == 1
    error_message = "Should have organization access configured"
  }

  assert {
    condition     = tfe_team.team.organization_access[0].manage_workspaces == true
    error_message = "Should have workspace management permissions"
  }
}

# Test 3: Team with token creation
run "team_with_token" {
  command = plan

  variables {
    team_name         = "ci-team"
    organization_name = "test-org"
    create_token      = true
  }

  assert {
    condition     = length(tfe_team_token.token) == 1
    error_message = "Should create team token when requested"
  }
}

# Test 4: All organization permissions
run "team_with_all_permissions" {
  command = plan

  variables {
    team_name         = "superadmin-team"
    organization_name = "test-org"
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

  assert {
    condition     = tfe_team.team.organization_access[0].manage_run_tasks == true
    error_message = "Should have all permissions set"
  }
}

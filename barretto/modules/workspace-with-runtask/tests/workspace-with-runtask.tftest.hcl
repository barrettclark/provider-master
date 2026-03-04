# Tests for workspace-with-runtask module

# Test 1: Minimal configuration
run "minimal_workspace" {
  command = plan

  variables {
    organization_name = "test-org"
    project_id        = "prj-test123"
    workspace_name    = "test-workspace"
    terraform_version = "1.10.0"
    run_task_id       = "task-test123"
  }

  assert {
    condition     = tfe_workspace.workspace.name == "test-workspace"
    error_message = "Workspace name does not match input"
  }

  assert {
    condition     = tfe_workspace.workspace.terraform_version == "1.10.0"
    error_message = "Terraform version does not match input"
  }

  assert {
    condition     = tfe_workspace_run_task.run_task.enforcement_level == "advisory"
    error_message = "Default enforcement level should be advisory"
  }

  assert {
    condition     = length(tfe_workspace_run_task.run_task.stages) == 1 && tfe_workspace_run_task.run_task.stages[0] == "post_plan"
    error_message = "Default stage should be post_plan"
  }
}

# Test 2: With VCS configuration
run "workspace_with_vcs" {
  command = plan

  variables {
    organization_name = "test-org"
    project_id        = "prj-test123"
    workspace_name    = "vcs-workspace"
    terraform_version = "1.10.0"
    run_task_id       = "task-test123"
    vcs_repo = {
      identifier         = "org/repo"
      oauth_token_id     = "ot-test123"
      branch             = "main"
      ingress_submodules = true
    }
    file_triggers_enabled = true
  }

  assert {
    condition     = length(tfe_workspace.workspace.vcs_repo) == 1
    error_message = "VCS repo should be configured"
  }

  assert {
    condition     = tfe_workspace.workspace.file_triggers_enabled == true
    error_message = "File triggers should be enabled for VCS workspace"
  }
}

# Test 3: Without VCS - file_triggers should be null (conditional logic)
run "workspace_without_vcs" {
  command = plan

  variables {
    organization_name = "test-org"
    project_id        = "prj-test123"
    workspace_name    = "no-vcs-workspace"
    terraform_version = "1.10.0"
    run_task_id       = "task-test123"
    vcs_repo          = null
  }

  assert {
    condition     = length(tfe_workspace.workspace.vcs_repo) == 0
    error_message = "VCS repo should not be configured"
  }

  # Note: file_triggers_enabled will be computed as null by the conditional:
  # file_triggers_enabled = var.vcs_repo != null ? var.file_triggers_enabled : null
  # But we can't assert null equality in plan mode with computed values
}

# Test 4: Custom run task settings
run "workspace_with_custom_run_task" {
  command = plan

  variables {
    organization_name          = "test-org"
    project_id                 = "prj-test123"
    workspace_name             = "custom-runtask-workspace"
    terraform_version          = "1.10.0"
    run_task_id                = "task-test123"
    run_task_stages            = ["pre_plan", "post_plan"]
    run_task_enforcement_level = "mandatory"
  }

  assert {
    condition     = length(tfe_workspace_run_task.run_task.stages) == 2
    error_message = "Run task should have 2 stages"
  }

  assert {
    condition     = contains(tfe_workspace_run_task.run_task.stages, "pre_plan")
    error_message = "Run task should include pre_plan stage"
  }

  assert {
    condition     = tfe_workspace_run_task.run_task.enforcement_level == "mandatory"
    error_message = "Run task enforcement should be mandatory"
  }
}

# Test 5: Verify tags are applied correctly
run "tags_applied" {
  command = plan

  variables {
    organization_name = "test-org"
    project_id        = "prj-test123"
    workspace_name    = "tagged-workspace"
    terraform_version = "1.10.0"
    run_task_id       = "task-test123"
    tag_names         = ["production", "app:api"]
  }

  assert {
    condition     = length(tfe_workspace.workspace.tag_names) == 2
    error_message = "Workspace should have 2 tags"
  }

  assert {
    condition     = contains(tfe_workspace.workspace.tag_names, "production")
    error_message = "Tags should include production"
  }
}

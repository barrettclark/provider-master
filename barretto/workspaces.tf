# Long name workspaces
resource "tfe_workspace" "long_name_workspaces" {
  organization = local.organization_name
  for_each     = local.long_name_workspaces
  name         = each.value
  project_id   = tfe_project.prj_long_name.id
  tag_names    = ["app:example"]
}

# Contain workspace with variables
resource "tfe_workspace" "contain" {
  name                          = "contain"
  organization                  = local.organization_name
  structured_run_output_enabled = false
}

resource "tfe_variable" "contain_a" {
  key          = "a"
  category     = "terraform"
  workspace_id = tfe_workspace.contain.id
}

resource "tfe_variable" "contain_aaa" {
  key          = "aaa"
  value        = var.aaa
  category     = "terraform"
  workspace_id = tfe_workspace.contain.id
}

resource "tfe_variable" "contain_bbb" {
  key          = "bbb"
  value        = var.bbb
  category     = "terraform"
  workspace_id = tfe_workspace.contain.id
}

resource "tfe_variable" "contain_hclvar1" {
  key          = "hclvar1"
  value        = file("contain_var.hcl")
  category     = "terraform"
  description  = "variable"
  hcl          = true
  sensitive    = false
  workspace_id = tfe_workspace.contain.id
}

resource "tfe_workspace_run_task" "contain_run_task" {
  workspace_id      = tfe_workspace.contain.id
  task_id           = tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
  stage             = local.default_run_task.stage
  enforcement_level = local.default_run_task.enforcement_level
}

# Dev workspace with notification and team access
resource "tfe_workspace" "dev" {
  name         = "dev"
  organization = local.organization_name
}

resource "tfe_variable" "dev_idpub" {
  key          = "idpub"
  category     = "terraform"
  workspace_id = tfe_workspace.dev.id
  value        = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC68PHkObbQx97Zmb9frycadinKm55clKzr4k1DqQN3ZLwcQNmfznBIrVqDipPS6N4o6Piew7Snxwb8P6cIKrHTX9dsRXUf5JgX9TgfJntpON9ii3Dlh7ctmg2iRDCvC+6vd5krL6MTN6TqXJeINB7QibbUksSGY4u4B9P9Yg1UwMOt0sA8EIZELZLqlmW3d9xjac0WrUkXSq3r5Fttb4QMU/RrlkX3fE40bn+YcOSYGkSaqBYFdDHWDNzvCvfmZsQ1zJ1cdNp8qUwgd09J+uZ+p5pXLrsWyXlirBnXlbm95TtiY2qzEZJ/L36WsSnVIlAfmlvHaH5O/aqI8ZKrHQoSmLBbkt4FFlm4auQgQPBBRwK/x9+YcgzmtD1Sgm01jGGGr/WeLEoyhDhMH6uUPNweWVh/aif/9TmPRCKYaXfvBWWzF0Tqb74KLLt4ItSAhInessowSbGrDByz9y9sDtF8Fv1qur0udNFSrzo0saKgjHheLKy1hDxxUb34TCFzP/M= barrettclark@barrettclark-C02G60Y5MD6Q"
}

resource "tfe_notification_configuration" "dev-notification" {
  name             = "Email Notification"
  workspace_id     = tfe_workspace.dev.id
  enabled          = true
  destination_type = "email"
  triggers         = ["run:completed", "run:applying", "run:planning", "run:needs_attention"]
  email_user_ids   = [data.tfe_organization_membership.owner.user_id]
}

resource "tfe_team_access" "dev-limited" {
  workspace_id = tfe_workspace.dev.id
  team_id      = tfe_team.limited.id
  permissions {
    runs              = "read"
    variables         = "none"
    state_versions    = "read-outputs"
    sentinel_mocks    = "none"
    run_tasks         = false
    workspace_locking = false
  }
}

# Terraform minimum workspace with VCS
resource "tfe_workspace" "terraform-minimum" {
  name                  = "terraform-minimum"
  organization          = local.organization_name
  terraform_version     = "1.4.1"
  file_triggers_enabled = false
  vcs_repo {
    identifier     = "barrettclark/terraform-minimum"
    oauth_token_id = tfe_oauth_client.github-oauth-client.oauth_token_id
  }
}

resource "tfe_workspace_run_task" "terraform-minimum_run_task" {
  workspace_id      = tfe_workspace.terraform-minimum.id
  task_id           = tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
  stage             = local.default_run_task.stage
  enforcement_level = local.default_run_task.enforcement_level
}

terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.48.0"
    }
  }
}

variable "organization_name" {
  description = "The organization name"
  type        = string
}

variable "project_id" {
  description = "The project ID for the workspace"
  type        = string
}

variable "workspace_name" {
  description = "The workspace name"
  type        = string
}

variable "terraform_version" {
  description = "The desired Terraform version"
  type        = string
}

variable "tag_names" {
  description = "List of tags for this workspace"
  type        = list(string)
  default     = []
}

variable "run_task_id" {
  description = "The organization run task ID to attach"
  type        = string
}

variable "run_task_stage" {
  description = "The stage for the run task (pre_plan, post_plan, pre_apply)"
  type        = string
  default     = "post_plan"
}

variable "run_task_enforcement_level" {
  description = "The enforcement level for the run task (advisory, mandatory)"
  type        = string
  default     = "advisory"
}

variable "vcs_repo" {
  description = "VCS repository configuration"
  type = object({
    identifier         = string
    oauth_token_id     = string
    branch             = optional(string)
    ingress_submodules = optional(bool)
  })
  default = null
}

variable "file_triggers_enabled" {
  description = "Enable file triggers for VCS-backed workspaces"
  type        = bool
  default     = true
}

variable "structured_run_output_enabled" {
  description = "Enable structured run output"
  type        = bool
  default     = null
}

variable "notification_configuration" {
  description = "Notification configuration for the workspace"
  type = object({
    name             = string
    enabled          = bool
    destination_type = string
    triggers         = list(string)
    email_user_ids   = optional(list(string))
    url              = optional(string)
  })
  default = null
}

variable "team_access" {
  description = "Team access configuration for the workspace"
  type = map(object({
    team_id = string
    permissions = object({
      runs              = string
      variables         = string
      state_versions    = string
      sentinel_mocks    = string
      run_tasks         = bool
      workspace_locking = bool
    })
  }))
  default = {}
}

resource "tfe_workspace" "workspace" {
  name                          = var.workspace_name
  organization                  = var.organization_name
  project_id                    = var.project_id
  terraform_version             = var.terraform_version
  tag_names                     = var.tag_names
  file_triggers_enabled         = var.vcs_repo != null ? var.file_triggers_enabled : null
  structured_run_output_enabled = var.structured_run_output_enabled

  dynamic "vcs_repo" {
    for_each = var.vcs_repo != null ? [var.vcs_repo] : []
    content {
      identifier         = vcs_repo.value.identifier
      oauth_token_id     = vcs_repo.value.oauth_token_id
      branch             = vcs_repo.value.branch
      ingress_submodules = vcs_repo.value.ingress_submodules
    }
  }
}

resource "tfe_workspace_run_task" "run_task" {
  workspace_id      = tfe_workspace.workspace.id
  task_id           = var.run_task_id
  stage             = var.run_task_stage
  enforcement_level = var.run_task_enforcement_level
}

resource "tfe_notification_configuration" "notification" {
  count = var.notification_configuration != null ? 1 : 0

  name             = var.notification_configuration.name
  workspace_id     = tfe_workspace.workspace.id
  enabled          = var.notification_configuration.enabled
  destination_type = var.notification_configuration.destination_type
  triggers         = var.notification_configuration.triggers
  email_user_ids   = var.notification_configuration.email_user_ids
  url              = var.notification_configuration.url
}

resource "tfe_team_access" "team_access" {
  for_each = var.team_access

  workspace_id = tfe_workspace.workspace.id
  team_id      = each.value.team_id

  permissions {
    runs              = each.value.permissions.runs
    variables         = each.value.permissions.variables
    state_versions    = each.value.permissions.state_versions
    sentinel_mocks    = each.value.permissions.sentinel_mocks
    run_tasks         = each.value.permissions.run_tasks
    workspace_locking = each.value.permissions.workspace_locking
  }
}

output "workspace_id" {
  description = "The workspace ID"
  value       = tfe_workspace.workspace.id
}

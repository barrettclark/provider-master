variable "organization_name" {
  description = "The organization name"
  type        = string
}

variable "team_name" {
  description = "The team name"
  type        = string
}

variable "organization_access" {
  description = "Organization-level permissions for the team"
  type = object({
    manage_membership       = optional(bool)
    manage_modules          = optional(bool)
    manage_policies         = optional(bool)
    manage_policy_overrides = optional(bool)
    manage_projects         = optional(bool)
    manage_providers        = optional(bool)
    manage_run_tasks        = optional(bool)
    manage_vcs_settings     = optional(bool)
    manage_workspaces       = optional(bool)
    read_projects           = optional(bool)
    read_workspaces         = optional(bool)
  })
  default = null
}

variable "create_token" {
  description = "Whether to create a team token"
  type        = bool
  default     = false
}

variable "force_regenerate_token" {
  description = "Whether to force regenerate the team token"
  type        = bool
  default     = false
}

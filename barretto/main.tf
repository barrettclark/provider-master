terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.48.0"
    }
  }
  cloud {
    hostname     = "app.staging.terraform.io"
    organization = "barretto"

    workspaces {
      name = "provider-orchestrator-barretto"
    }
  }
}

provider "tfe" {
  hostname = var.hostname
  token    = var.tfe_token
}

# Variables
variable "hostname" {
  type = string
}
variable "owner_email" {
  type = string
}
variable "tfe_token" {
  type = string
}

# --- ORGANIZATION
# Create an organization
# NOTE: Once the organization is created you need to update the subscription
# to allow the creation of teams
# https://app.staging.terraform.io/app/admin/organizations/barretto-provider-made
resource "tfe_organization" "org" {
  name                          = "barretto-provider-made"
  email                         = var.owner_email
  allow_force_delete_workspaces = true
}

#
# --- Below this line can be run after changing the organization subscription
#
# Organization Token
resource "tfe_organization_token" "org_token" {
  organization = tfe_organization.org.name
}
output "org_token" {
  value     = tfe_organization_token.org_token.token
  sensitive = true
}

# --- AGENT POOLS
# Create an Agent Pool
resource "tfe_agent_pool" "agent-pool" {
  name                = "barrett-pool"
  organization        = tfe_organization.org.name
  organization_scoped = true
}

# --- USERS
# Additional user in organization
resource "tfe_organization_membership" "bclark1" {
  organization = tfe_organization.org.name
  email        = "bclark1@yahoo.com"
}

# --- TEAMS
data "tfe_team" "owners" {
  organization = tfe_organization.org.id
  name         = "owners"
}

resource "tfe_team" "k8s" {
  name         = "k8s"
  organization = tfe_organization.org.name
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
  organization = tfe_organization.org.name
  organization_access {}
}

resource "tfe_team_member" "k8s_members" {
  team_id  = tfe_team.k8s.id
  username = tfe_organization_membership.bclark1.username
}
resource "tfe_team_member" "limited_members" {
  team_id  = tfe_team.limited.id
  username = tfe_organization_membership.bclark1.username
}

# --- PROJECTS
# Create a project
resource "tfe_project" "prj_long_name" {
  organization = tfe_organization.org.name
  name         = "a_really_long_name"
}
resource "tfe_project" "project1" {
  organization = tfe_organization.org.name
  name         = "project1"
}

# --- RUN TASKS
resource "tfe_organization_run_task" "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW" {
  organization = tfe_organization.org.name
  url          = "http://example.com"
  name         = "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW-name"
  enabled      = true
  description  = "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur,"
}

# --- WORKSPACES
# Create workspaces
locals {
  long_name_workspaces = toset([
    "a_really_long_name_that_i_dont_want_to_type_a_really_long_name_i_dont_want_to_type_test",
    "a_really_long_name_that_i_dont_want_to_type_a_really_long_name_i_dont_want_to_type_prod"
  ])
}
resource "tfe_workspace" "long_name_workspaces" {
  organization = tfe_organization.org.name
  for_each     = local.long_name_workspaces
  name         = each.value
  project_id   = tfe_project.prj_long_name.id
  tag_names    = ["app:example"]
}

resource "tfe_workspace" "contain" {
  name                          = "contain"
  organization                  = tfe_organization.org.name
  structured_run_output_enabled = false
}
resource "tfe_variable" "a" {
  key          = "a"
  category     = "terraform"
  workspace_id = tfe_workspace.contain.id
}
resource "tfe_variable" "aaa" {
  key          = "aaa"
  value        = " leading space"
  category     = "terraform"
  workspace_id = tfe_workspace.contain.id
}
resource "tfe_variable" "bbb" {
  key          = "bbb"
  category     = "terraform"
  workspace_id = tfe_workspace.contain.id
}
resource "tfe_workspace_run_task" "contain-WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW" {
  workspace_id      = resource.tfe_workspace.contain.id
  task_id           = resource.tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
  stage             = "post_plan"
  enforcement_level = "advisory"
}


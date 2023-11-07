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
variable "github_oauth_token" {
  type = string
}
variable "hostname" {
  type = string
}
variable "owner_email" {
  type = string
}
variable "tfe_token" {
  type = string
}
variable "aws_access_key_id" {
  type = string
}
variable "aws_secret_access_key" {
  type = string
}

# --- ORGANIZATION
# Create an organization
# NOTE: Once the organization is created you need to update the subscription
# to allow the creation of teams
# https://app.staging.terraform.io/app/admin/organizations/barretto-provider-made
resource "tfe_organization" "org" {
  name                                                    = "barretto-provider-made"
  email                                                   = var.owner_email
  allow_force_delete_workspaces                           = true
  assessments_enforced                                    = true
  cost_estimation_enabled                                 = true
  send_passing_statuses_for_untriggered_speculative_plans = true
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
data "tfe_organization_membership" "owner" {
  organization = tfe_organization.org.id
  email        = var.owner_email
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
data "tfe_project" "default" {
  organization = tfe_organization.org.name
  name         = "Default Project"
}
resource "tfe_project" "prj_long_name" {
  organization = tfe_organization.org.name
  name         = "a_really_long_name"
}
resource "tfe_project" "project1" {
  organization = tfe_organization.org.name
  name         = "project1"
}
resource "tfe_project" "helloworld" {
  organization = tfe_organization.org.name
  name         = "helloworld"
}

# --- RUN TASKS
resource "tfe_organization_run_task" "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW" {
  organization = tfe_organization.org.name
  url          = "http://example.com"
  name         = "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW-name"
  enabled      = true
  description  = "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur,"
}

# --- OAUTH CLIENTS
resource "tfe_oauth_client" "github-oauth-client" {
  name             = "github-oauth-client"
  organization     = tfe_organization.org.name
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  oauth_token      = var.github_oauth_token
  service_provider = "github"
}

# --- VARIABLE SETS
resource "tfe_variable_set" "aws-credentials" {
  name         = "AWS Credentials"
  organization = tfe_organization.org.name
}
resource "tfe_variable" "aws-access-key" {
  key             = "AWS_ACCESS_KEY_ID"
  value           = var.aws_access_key_id
  category        = "env"
  variable_set_id = tfe_variable_set.aws-credentials.id
  sensitive       = true
}
resource "tfe_variable" "aws-secret-access-key" {
  key             = "AWS_SECRET_ACCESS_KEY"
  value           = var.aws_secret_access_key
  category        = "env"
  variable_set_id = tfe_variable_set.aws-credentials.id
  sensitive       = true
}

# --- POLICIES
resource "tfe_policy" "tag-required" {
  name         = "tag-required"
  description  = "The helloworld tag is required"
  organization = tfe_organization.org.name
  kind         = "sentinel"
  enforce_mode = "soft-mandatory"
  policy       = <<EOT
import "tfrun"
main = "helloworld" in tfrun.workspace.tags
EOT
}

# --- POLICY SETS
resource "tfe_policy_set" "helloworld-tag-required" {
  name         = "helloworld-tag-required"
  description  = "Soft require the helloworld tag on all workspaces in the Default project"
  organization = tfe_organization.org.name
  kind         = "sentinel"
  policy_ids   = [tfe_policy.tag-required.id]
}
resource "tfe_project_policy_set" "helloworld-tag-required" {
  policy_set_id = tfe_policy_set.helloworld-tag-required.id
  project_id    = data.tfe_project.default.id
}

resource "tfe_policy_set" "learn-terraform-enforce-policies" {
  name          = "learn-terraform-enforce-policies"
  description   = "A brand new policy set"
  organization  = tfe_organization.org.name
  kind          = "sentinel"
  policies_path = "policies/my-policy-set"
  workspace_ids = [module.wk2.workspace_id]

  vcs_repo {
    identifier         = "barrettclark/learn-terraform-enforce-policies"
    branch             = "master"
    ingress_submodules = false
    oauth_token_id     = tfe_oauth_client.github-oauth-client.oauth_token_id
  }
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

resource "tfe_workspace" "dev" {
  name         = "dev"
  organization = tfe_organization.org.name
}
resource "tfe_variable" "idpub" {
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

module "foo" {
  source            = "./modules/workspace-with-runtask"
  organization_name = tfe_organization.org.name
  project_id        = data.tfe_project.default.id
  workspace_name    = "foo"
  terraform_version = "0.12.0"
  run_task_id       = resource.tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
}
resource "tfe_variable" "foo-a" {
  key          = "a"
  category     = "terraform"
  workspace_id = module.foo.workspace_id
}

module "greedy" {
  source            = "./modules/workspace-with-runtask"
  organization_name = tfe_organization.org.name
  project_id        = data.tfe_project.default.id
  workspace_name    = "greedy"
  terraform_version = "1.3.7"
  run_task_id       = resource.tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
}

module "greedy2" {
  source            = "./modules/workspace-with-runtask"
  organization_name = tfe_organization.org.name
  project_id        = data.tfe_project.default.id
  workspace_name    = "greedy2"
  terraform_version = "1.3.7"
  run_task_id       = resource.tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
}

module "hw1" {
  source            = "./modules/workspace-with-runtask"
  organization_name = tfe_organization.org.name
  project_id        = data.tfe_project.default.id
  workspace_name    = "hw1"
  terraform_version = "1.5.1"
  tag_names         = ["helloworld"]
  run_task_id       = resource.tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
}

module "hw2" {
  source            = "./modules/workspace-with-runtask"
  organization_name = tfe_organization.org.name
  project_id        = data.tfe_project.default.id
  workspace_name    = "hw2"
  terraform_version = "1.5.1"
  tag_names         = ["helloworld"]
  run_task_id       = resource.tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
}

resource "tfe_workspace" "terraform-minimum" {
  name                  = "terraform-minimum"
  organization          = tfe_organization.org.name
  terraform_version     = "1.4.1"
  file_triggers_enabled = false
  vcs_repo {
    identifier     = "barrettclark/terraform-minimum"
    oauth_token_id = tfe_oauth_client.github-oauth-client.oauth_token_id
  }
}
resource "tfe_workspace_run_task" "terraform-minimum-WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW" {
  workspace_id      = resource.tfe_workspace.terraform-minimum.id
  task_id           = resource.tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
  stage             = "post_plan"
  enforcement_level = "advisory"
}

module "wk1" {
  source            = "./modules/workspace-with-runtask"
  organization_name = tfe_organization.org.name
  project_id        = data.tfe_project.default.id
  workspace_name    = "wk1"
  terraform_version = "1.4.4"
  run_task_id       = resource.tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
}
resource "tfe_workspace_variable_set" "wk1-aws-credentials" {
  workspace_id    = module.wk1.workspace_id
  variable_set_id = tfe_variable_set.aws-credentials.id
}

module "wk2" {
  source            = "./modules/workspace-with-runtask"
  organization_name = tfe_organization.org.name
  project_id        = data.tfe_project.default.id
  workspace_name    = "wk2"
  terraform_version = "1.4.4"
  run_task_id       = resource.tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
}

resource "tfe_policy" "tag_required" {
  name         = "tag-required"
  description  = "The helloworld tag is required"
  organization = local.organization_name
  kind         = "sentinel"
  enforce_mode = "soft-mandatory"
  policy       = <<EOT
import "tfrun"
main = "helloworld" in tfrun.workspace.tags
EOT
}

resource "tfe_policy_set" "helloworld_tag_required" {
  name         = "helloworld-tag-required"
  description  = "Soft require the helloworld tag on all workspaces in the Default project"
  organization = local.organization_name
  kind         = "sentinel"
  policy_ids   = [tfe_policy.tag_required.id]
}

resource "tfe_project_policy_set" "helloworld_tag_required" {
  policy_set_id = tfe_policy_set.helloworld_tag_required.id
  project_id    = data.tfe_project.default.id
}

resource "tfe_policy_set" "learn_terraform_enforce_policies" {
  name          = "learn-terraform-enforce-policies"
  description   = "A brand new policy set"
  organization  = local.organization_name
  kind          = "sentinel"
  policies_path = "policies/my-policy-set"
  workspace_ids = [module.workspaces["wk2"].workspace_id]

  vcs_repo {
    identifier         = "barrettclark/learn-terraform-enforce-policies"
    branch             = "master"
    ingress_submodules = false
    oauth_token_id     = tfe_oauth_client.github_oauth_client.oauth_token_id
  }
}

# Module-based workspaces using standardized configuration
module "workspaces" {
  source   = "./modules/workspace-with-runtask"
  for_each = local.workspaces

  organization_name = local.organization_name
  project_id        = each.value.project_id
  workspace_name    = each.key
  terraform_version = each.value.terraform_version
  tag_names         = each.value.tag_names
  run_task_id       = tfe_organization_run_task.WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.id
}

# Additional workspace-specific resources
resource "tfe_variable" "foo_a" {
  key          = "a"
  category     = "terraform"
  workspace_id = module.workspaces["foo"].workspace_id
}

resource "tfe_workspace_variable_set" "wk1_aws_credentials" {
  workspace_id    = module.workspaces["wk1"].workspace_id
  variable_set_id = tfe_variable_set.aws-credentials.id
}

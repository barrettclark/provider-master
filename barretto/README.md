# Barretto Terraform Configuration

This directory contains Terraform configuration for managing Terraform Cloud/Enterprise resources for the `barretto-provider-made` organization.

## Structure

### Configuration Files
- `main.tf` - Terraform and provider configuration
- `variables.tf` - Variable declarations
- `locals.tf` - Local values and common configurations
- `data.tf` - Data sources
- `organization.tf` - Organization, tokens, memberships, and agent pools
- `teams.tf` - Team module configurations and team members
- `projects.tf` - Projects
- `run-tasks.tf` - Organization run tasks
- `oauth.tf` - OAuth clients for VCS integration
- `variable-sets.tf` - Variable set module configurations
- `policies.tf` - Policies and policy sets
- `workspaces.tf` - Workspace resources (non-module based)
- `workspace-modules.tf` - Module-based workspace configurations
- `outputs.tf` - Output values

### Reusable Modules
- `modules/workspace-with-runtask/` - Module for creating workspaces with run tasks
- `modules/team/` - Module for creating teams with optional tokens
- `modules/variable-set/` - Module for creating variable sets with multiple variables

## Prerequisites

1. Terraform >= 1.4.0
2. Terraform Cloud/Enterprise API token
3. GitHub OAuth token (if using VCS integration)
4. AWS credentials (if using AWS variable sets)

## Setup

1. Copy `main.auto.tfvars.example` to `main.auto.tfvars` and fill in non-sensitive values
2. Set sensitive variables as environment variables:
   ```bash
   export TF_VAR_tfe_token="your-token"
   export TF_VAR_github_oauth_token="your-github-token"
   export TF_VAR_aws_access_key_id="your-aws-key"
   export TF_VAR_aws_secret_access_key="your-aws-secret"
   ```

## Important Notes

- **Organization Subscription**: After creating the organization, you must update the subscription to allow team creation. See the comment in `organization.tf` for the admin URL.
- **Sensitive Values**: Never commit `main.auto.tfvars` with real credentials to version control.
- **Workspace Modules**: Most workspaces are created using the `workspace-with-runtask` module for consistency. Workspaces with special requirements (VCS, notifications, etc.) are defined directly in `workspaces.tf`.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Workspace Configuration

Workspace configurations are defined in `locals.tf` under the `workspaces` map. To add a new workspace:

1. Add an entry to the `workspaces` map in `locals.tf`
2. The module will automatically create the workspace with the specified configuration
3. For workspace-specific resources (variables, variable sets), add them to `workspace-modules.tf`

### Module-Based Workspaces

The `workspace-with-runtask` module supports the following features:

**Required parameters:**
- `workspace_name` - The workspace name
- `organization_name` - The organization name
- `project_id` - The project ID
- `terraform_version` - Terraform version
- `run_task_id` - Organization run task ID to attach

**Optional parameters:**
- `tag_names` - List of tags (default: [])
- `vcs_repo` - VCS repository configuration with identifier, oauth_token_id, branch, and ingress_submodules
- `file_triggers_enabled` - Enable file triggers for VCS workspaces (default: true)
- `structured_run_output_enabled` - Enable structured run output
- `notification_configuration` - Notification settings including name, enabled, destination_type, triggers, and email_user_ids or url
- `team_access` - Map of team access configurations with team_id and permissions
- `run_task_stage` - Run task stage (default: "post_plan")
- `run_task_enforcement_level` - Run task enforcement (default: "advisory")

### Special Workspaces

Workspaces with unique requirements (like `contain`, `dev`, `terraform-minimum`) are defined directly in `workspaces.tf` for clarity, but could be migrated to use the enhanced module with optional parameters if needed.

## Team Management

Teams are managed using the `team` module for consistency and reusability.

### Adding a New Team

```hcl
module "new_team" {
  source = "./modules/team"

  organization_name = local.organization_name
  team_name         = "team-name"
  create_token      = true  # Optional: set to true to generate a team token

  organization_access = {
    manage_workspaces = true
    read_workspaces   = true
    # Add other permissions as needed
  }
}

# Add team members at root level
resource "tfe_team_member" "new_team_members" {
  team_id  = module.new_team.team_id
  username = tfe_organization_membership.user.username
  depends_on = [tfe_organization_membership.user]
}
```

## Variable Set Management

Variable sets are managed using the `variable-set` module for consistency.

### Adding a New Variable Set

```hcl
module "new_credentials" {
  source = "./modules/variable-set"

  organization_name = local.organization_name
  name              = "New Credentials"

  variables = {
    var1 = {
      key       = "VAR_NAME_1"
      value     = var.input_value_1
      category  = "env"  # or "terraform"
      sensitive = true
    }
    var2 = {
      key       = "VAR_NAME_2"
      value     = var.input_value_2
      category  = "env"
      sensitive = false
    }
  }
}

# Attach to workspace
resource "tfe_workspace_variable_set" "workspace_attachment" {
  workspace_id    = module.workspaces["workspace_name"].workspace_id
  variable_set_id = module.new_credentials.variable_set_id
}
```

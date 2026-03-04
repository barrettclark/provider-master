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

1. Terraform ~> 1.10 (1.10.0 or later)
2. TFE Provider ~> 0.60.0
3. Terraform Cloud/Enterprise API token
4. GitHub OAuth token (if using VCS integration)
5. AWS credentials (if using AWS variable sets)

## Setup

### Credential Management

Sensitive credentials should **never** be committed to version control. Use one of these methods:

**Option 1: Environment Variables (Recommended for Local)**
```bash
cp .env.example .env
# Edit .env with your actual credentials
source .env
```

**Option 2: HCP Terraform Workspace Variables (Recommended for Remote)**
Set these as sensitive workspace variables in HCP Terraform:
- `TF_VAR_tfe_token`
- `TF_VAR_github_oauth_token`
- `TF_VAR_aws_access_key_id`
- `TF_VAR_aws_secret_access_key`

**Option 3: Local tfvars (Gitignored)**
```bash
# Create terraform.tfvars (automatically excluded from git)
cat > terraform.tfvars <<EOF
tfe_token             = "your-token"
github_oauth_token    = "your-github-token"
aws_access_key_id     = "your-aws-key"
aws_secret_access_key = "your-aws-secret"
EOF
```

### Variable Validation

All variables include validation rules:
- `hostname` - Must be a valid DNS name
- `owner_email` - Must be a valid email address
- `tfe_token` - Minimum 20 characters
- `github_oauth_token` - Must match GitHub token format (ghp_, gho_, etc.)
- `aws_access_key_id` - Must match AWS format (AKIA...)
- `aws_secret_access_key` - Must be exactly 40 characters

These validations catch configuration errors early, before API calls.

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
- `run_task_stages` - Run task stages as a list (default: ["post_plan"])
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

## Module Testing

All modules include comprehensive test suites using Terraform's native testing framework.

### Running Tests

**First-time setup** - Initialize each module (one-time):
```bash
(cd modules/workspace-with-runtask && terraform init)
(cd modules/team && terraform init)
(cd modules/variable-set && terraform init)
```

**Test a single module** (from barretto directory):
```bash
(cd modules/workspace-with-runtask && terraform test)
(cd modules/team && terraform test)
(cd modules/variable-set && terraform test)
```

**Test all modules:**
```bash
for module in modules/*/; do
  echo "Testing $module"
  (cd "$module" && terraform test)
done
```

### Test Coverage

- **workspace-with-runtask**: 5 test scenarios covering minimal config, VCS integration, custom run tasks, and outputs
- **team**: 4 test scenarios covering basic teams, organization access, tokens, and permissions
- **variable-set**: 6 test scenarios covering empty sets, single/multiple variables, sensitive vars, HCL vars, and descriptions

Tests use `command = plan` to validate configuration without making actual API calls.

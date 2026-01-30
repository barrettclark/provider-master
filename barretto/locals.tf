locals {
  organization_name = "barretto-provider-made"

  # Common run task configuration
  default_run_task = {
    stage             = "post_plan"
    enforcement_level = "advisory"
  }

  # Workspace configurations for module-based workspaces
  # All workspaces share a common structure with optional fields
  workspaces = {
    # Standard workspaces
    foo = {
      terraform_version = "0.12.0"
      tag_names         = []
      project_id        = data.tfe_project.default.id
    }
    greedy = {
      terraform_version = "1.3.7"
      tag_names         = []
      project_id        = data.tfe_project.default.id
    }
    greedy2 = {
      terraform_version = "1.3.7"
      tag_names         = []
      project_id        = data.tfe_project.default.id
    }
    hw1 = {
      terraform_version = "1.5.1"
      tag_names         = ["helloworld"]
      project_id        = data.tfe_project.default.id
    }
    hw2 = {
      terraform_version = "1.5.1"
      tag_names         = ["helloworld"]
      project_id        = data.tfe_project.default.id
    }
    wk1 = {
      terraform_version = "1.4.4"
      tag_names         = []
      project_id        = data.tfe_project.default.id
    }
    wk2 = {
      terraform_version = "1.4.4"
      tag_names         = []
      project_id        = data.tfe_project.default.id
    }
  }

  # Legacy reference for long name workspaces (kept for backwards compatibility)
  # These workspaces are managed directly in workspaces.tf due to special project assignment
  long_name_workspaces = toset([
    "a_really_long_name_that_i_dont_want_to_type_a_really_long_name_i_dont_want_to_type_test",
    "a_really_long_name_that_i_dont_want_to_type_a_really_long_name_i_dont_want_to_type_prod"
  ])
}

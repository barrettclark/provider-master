# Tests for variable-set module

# Test 1: Empty variable set
run "empty_variable_set" {
  command = plan

  variables {
    name              = "test-varset"
    organization_name = "test-org"
    variables         = {}
  }

  assert {
    condition     = tfe_variable_set.set.name == "test-varset"
    error_message = "Variable set name does not match"
  }

  assert {
    condition     = length(tfe_variable.variables) == 0
    error_message = "Should have no variables"
  }
}

# Test 2: Single variable
run "single_variable" {
  command = plan

  variables {
    name              = "single-var-set"
    organization_name = "test-org"
    variables = {
      test_var = {
        key      = "TEST_VAR"
        value    = "test-value"
        category = "env"
      }
    }
  }

  assert {
    condition     = length(tfe_variable.variables) == 1
    error_message = "Should have exactly one variable"
  }

  assert {
    condition     = tfe_variable.variables["test_var"].key == "TEST_VAR"
    error_message = "Variable key does not match"
  }
}

# Test 3: Multiple variables with different types
run "multiple_variables" {
  command = plan

  variables {
    name              = "multi-var-set"
    organization_name = "test-org"
    variables = {
      env_var = {
        key      = "DATABASE_URL"
        value    = "postgres://localhost"
        category = "env"
      }
      tf_var = {
        key      = "region"
        value    = "us-west-2"
        category = "terraform"
      }
    }
  }

  assert {
    condition     = length(tfe_variable.variables) == 2
    error_message = "Should have two variables"
  }
}

# Test 4: Sensitive variable
run "sensitive_variable" {
  command = plan

  variables {
    name              = "sensitive-var-set"
    organization_name = "test-org"
    variables = {
      secret = {
        key       = "API_KEY"
        value     = "super-secret"
        category  = "env"
        sensitive = true
      }
    }
  }

  assert {
    condition     = tfe_variable.variables["secret"].sensitive == true
    error_message = "Variable should be marked as sensitive"
  }
}

# Test 5: HCL variable
run "hcl_variable" {
  command = plan

  variables {
    name              = "hcl-var-set"
    organization_name = "test-org"
    variables = {
      map_var = {
        key      = "tags"
        value    = "{\"env\" = \"prod\"}"
        category = "terraform"
        hcl      = true
      }
    }
  }

  assert {
    condition     = tfe_variable.variables["map_var"].hcl == true
    error_message = "Variable should be marked as HCL"
  }
}

# Test 6: Variable with description
run "variable_with_description" {
  command = plan

  variables {
    name              = "described-var-set"
    organization_name = "test-org"
    variables = {
      documented = {
        key         = "FEATURE_FLAG"
        value       = "true"
        category    = "env"
        description = "Enables the new feature"
      }
    }
  }

  assert {
    condition     = tfe_variable.variables["documented"].description == "Enables the new feature"
    error_message = "Variable description should be set"
  }
}

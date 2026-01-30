terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.48.0"
    }
  }
}

resource "tfe_variable_set" "set" {
  name         = var.name
  organization = var.organization_name
}

resource "tfe_variable" "variables" {
  for_each = var.variables

  key             = each.value.key
  value           = each.value.value
  category        = each.value.category
  variable_set_id = tfe_variable_set.set.id
  sensitive       = try(each.value.sensitive, false)
  hcl             = try(each.value.hcl, false)
  description     = try(each.value.description, null)
}

terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  cloud {
    hostname     = "app.staging.terraform.io"
    organization = "barretto"

    workspaces {
      name = "excessive-parent"
    }
  }
  required_providers {
    tfe = {
      source = "hashicorp/tfe"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "token" {}
provider "tfe" {
  hostname     = "app.staging.terraform.io"
  token        = var.token
  organization = "barretto"
}

# Workspace with an excessive amount of variables, resources, outputs, tags
locals {
  excessive_length = 200
  tag_map          = tomap({ "tag" = local.excessive_length })
  excessive_tags = {
    for name, count in local.tag_map : name => [
      for i in range(local.excessive_length) : format("%s%03d", name, i)
    ]
  }
}

output "excessive_tags" {
  value = local.excessive_tags.tag
}

data "tfe_organization" "barretto" {
  name = "barretto"
}
resource "tfe_workspace" "excessive-child" {
  name         = "excessive-child"
  organization = data.tfe_organization.barretto.name
  tag_names    = concat(local.excessive_tags.tag, ["helloworld"])
}
resource "tfe_variable" "varssss" {
  count        = local.excessive_length
  key          = format("v%03d", count.index)
  value        = format("Variable %d", count.index)
  description  = "A generated variable"
  category     = "terraform"
  workspace_id = tfe_workspace.excessive-child.id
}
resource "random_pet" "petsss" {
  count = local.excessive_length
}

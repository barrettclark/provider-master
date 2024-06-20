terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.51.1"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.82.0"
    }
  }
  cloud {
    hostname     = "app.eu.terraform.io"
    organization = "TFC-Unification-Test-Org-2"

    workspaces {
      name = "provider-orchestrator-barretto"
    }
  }
}

provider "tfe" {
  hostname = var.hostname
  token    = var.tfe_token
}

provider "hcp" {}

# --- HCP THINGS
locals {
  hcp_project_id = "b9319abc-c38d-483d-ae36-59ba7327c6e9"
}

data "hcp_organization" "TFC-Unification-Test-Org-2" {
  # name = "TFC-Unification-Test-Org-2"
}

data "hcp_project" "example" {
  project = local.hcp_project_id
}

data "hcp_iam_policy" "example" {
  bindings = [
    {
      role = "roles/admin"
      principals = [
        "f03d1e96-3743-476f-a309-751f8d287513",
      ]
    },
  ]
}

# Team, Team Membership

# --- TFC THINGS

terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  required_providers {
    tfe = {
      source = "hashicorp/tfe"
      # version = "0.48.0"
    }
  }
  cloud {
    hostname     = "app.eu.terraform.io"
    organization = "TFC-Unification-Test-Org-2"

    workspaces {
      name = "provider-orchestrator-simple"
    }
  }
}

variable "hostname" {
  type    = string
  default = "app.eu.terraform.io"
}

variable "token" {
  type = string
}

provider "tfe" {
  hostname = var.hostname
  token    = var.token
}

# Create a workspace
resource "tfe_workspace" "child_workspace" {
  name         = "child-workspace"
  organization = "TFC-Unification-Test-Org-2"
  tag_names    = ["test", "app"]
}

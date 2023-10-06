terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.48.0"
    }
  }
  cloud {
    hostname     = "app.staging.terraform.io"
    organization = "barretto-simple"

    workspaces {
      name = "provider-orchestrator-simple"
    }
  }
}

variable "hostname" {
  type    = string
  default = "app.staging.terraform.io"
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
  organization = "barretto-simple"
  tag_names    = ["test", "app"]
}

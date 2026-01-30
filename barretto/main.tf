terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.48.0"
    }
  }
  cloud {
    hostname     = "app.staging.terraform.io"
    organization = "barretto"

    workspaces {
      name = "provider-orchestrator-barretto"
    }
  }
}

provider "tfe" {
  hostname = var.hostname
  token    = var.tfe_token
}

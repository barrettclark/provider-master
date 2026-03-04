terraform {
  required_version = "~> 1.10"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.60.0"
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

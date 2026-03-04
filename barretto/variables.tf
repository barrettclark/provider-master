variable "github_oauth_token" {
  description = "GitHub OAuth token for VCS integration"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^(ghp_|gho_|ghu_|ghs_|ghr_)[a-zA-Z0-9]{36,}$", var.github_oauth_token))
    error_message = "GitHub token must be a valid personal access token (starts with ghp_, gho_, ghu_, ghs_, or ghr_)."
  }
}

variable "hostname" {
  description = "Terraform Cloud/Enterprise hostname"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.hostname))
    error_message = "Hostname must be a valid DNS name."
  }
}

variable "owner_email" {
  description = "Email address of the organization owner"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner_email))
    error_message = "Must be a valid email address."
  }
}

variable "tfe_token" {
  description = "Terraform Cloud/Enterprise API token"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.tfe_token) > 20
    error_message = "TFE token must be at least 20 characters long."
  }
}

variable "aws_access_key_id" {
  description = "AWS access key ID for variable sets"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^AKIA[0-9A-Z]{16}$", var.aws_access_key_id))
    error_message = "AWS access key ID must start with AKIA and be 20 characters long."
  }
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for variable sets"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.aws_secret_access_key) == 40
    error_message = "AWS secret access key must be exactly 40 characters long."
  }
}

variable "aaa" {
  description = "Value for aaa variable in contain workspace"
  type        = string
  default     = " leading space"
}

variable "bbb" {
  description = "Value for bbb variable in contain workspace"
  type        = string
  default     = ""
}

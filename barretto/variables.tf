variable "github_oauth_token" {
  description = "GitHub OAuth token for VCS integration"
  type        = string
  sensitive   = true
}

variable "hostname" {
  description = "Terraform Cloud/Enterprise hostname"
  type        = string
}

variable "owner_email" {
  description = "Email address of the organization owner"
  type        = string
}

variable "tfe_token" {
  description = "Terraform Cloud/Enterprise API token"
  type        = string
  sensitive   = true
}

variable "aws_access_key_id" {
  description = "AWS access key ID for variable sets"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for variable sets"
  type        = string
  sensitive   = true
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

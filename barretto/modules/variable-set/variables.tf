variable "organization_name" {
  description = "The organization name"
  type        = string
}

variable "name" {
  description = "The variable set display name"
  type        = string
}

variable "variables" {
  description = "Map of variables to create in the variable set"
  type = map(object({
    key         = string
    value       = string
    category    = string # "terraform" or "env"
    sensitive   = optional(bool, false)
    hcl         = optional(bool, false)
    description = optional(string)
  }))
}

output "org_token" {
  description = "Organization API token"
  value       = tfe_organization_token.org_token.token
  sensitive   = true
}

output "k8s_token" {
  description = "K8s team API token"
  value       = tfe_team_token.k8s_token.token
  sensitive   = true
}

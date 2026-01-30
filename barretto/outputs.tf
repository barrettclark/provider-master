output "org_token" {
  description = "Organization API token"
  value       = tfe_organization_token.org_token.token
  sensitive   = true
}

output "k8s_token" {
  description = "K8s team API token"
  value       = module.k8s_team.team_token
  sensitive   = true
}

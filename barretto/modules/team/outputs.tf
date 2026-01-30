output "team_id" {
  description = "The team ID"
  value       = tfe_team.team.id
}

output "team_token" {
  description = "The team token (if created)"
  value       = var.create_token ? tfe_team_token.token[0].token : null
  sensitive   = true
}

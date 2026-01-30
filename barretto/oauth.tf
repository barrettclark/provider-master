resource "tfe_oauth_client" "github_oauth_client" {
  name             = "github-oauth-client"
  organization     = local.organization_name
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  oauth_token      = var.github_oauth_token
  service_provider = "github"
}

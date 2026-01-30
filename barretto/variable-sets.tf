resource "tfe_variable_set" "aws-credentials" {
  name         = "AWS Credentials"
  organization = local.organization_name
}

resource "tfe_variable" "aws-access-key" {
  key             = "AWS_ACCESS_KEY_ID"
  value           = var.aws_access_key_id
  category        = "env"
  variable_set_id = tfe_variable_set.aws-credentials.id
  sensitive       = true
}

resource "tfe_variable" "aws-secret-access-key" {
  key             = "AWS_SECRET_ACCESS_KEY"
  value           = var.aws_secret_access_key
  category        = "env"
  variable_set_id = tfe_variable_set.aws-credentials.id
  sensitive       = true
}

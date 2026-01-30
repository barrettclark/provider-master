module "aws_credentials" {
  source = "./modules/variable-set"

  organization_name = local.organization_name
  name              = "AWS Credentials"

  variables = {
    access_key = {
      key       = "AWS_ACCESS_KEY_ID"
      value     = var.aws_access_key_id
      category  = "env"
      sensitive = true
    }
    secret_key = {
      key       = "AWS_SECRET_ACCESS_KEY"
      value     = var.aws_secret_access_key
      category  = "env"
      sensitive = true
    }
  }
}

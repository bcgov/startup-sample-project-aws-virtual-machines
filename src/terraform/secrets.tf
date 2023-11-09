# secrets.tf

data "aws_secretsmanager_secret_version" "secrets" {  # create this manually
  secret_id = "resourcespace_secrets"
}

locals {
  secrets = jsondecode(
    data.aws_secretsmanager_secret_version.secrets.secret_string
  )
}

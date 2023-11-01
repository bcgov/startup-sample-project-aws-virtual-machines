locals {
  tfc_hostname     = "app.terraform.io"
  tfc_organization = "bcgov"
  target_env      = reverse(split("/", get_terragrunt_dir()))[0]
}

generate "remote_state" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "terraform-remote-state-lqc63d-${local.target_env}"
    key            = "remote.tfstate-admin"                # Path and name of the state file within the bucket
    region         = "ca-central-1"                        # AWS region where the bucket is located
    dynamodb_table = "terraform-remote-state-lock-lqc63d"  # Replace with either generated or custom DynamoDB table name
    encrypt        = true                                  # Enable encryption for the state file
  }
}
EOF
}

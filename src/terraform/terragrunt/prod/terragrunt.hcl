terraform {
  source = "../../"
}

include {
  path = find_in_parent_folders()
}

locals {
  instance_type = "t3.medium.elasticsearch"
  instance_count = 3
}

generate "dev_tfvars" {
  path              = "dev.auto.tfvars"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<-EOF
instance_type = "${local.instance_type}"
instance_count = "${local.instance_count}"
target_env="prod"
EOF
}
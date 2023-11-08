provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Gather VPC information from the network module

module "network" {
  source      = "git::https://github.com/BCDevOps/terraform-octk-aws-sea-network-info.git//?ref=master"
  environment = var.target_env
}

# Internal ALB 

# Use the default ALB that is pre-provisioned as part of the account creation
# This ALB has all traffic on *.LICENSE-PLATE-ENV.nimbus.cloud.gov.bc.ca routed to it
data "aws_alb" "main" {
  name = var.alb_name
}

# Redirect all traffic from the ALB to the target group
data "aws_alb_listener" "web" {
  load_balancer_arn = data.aws_alb.main.id
  port              = "443"
}

resource "aws_alb_target_group" "app" {
  name                 = var.app_name
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = module.network.aws_vpc.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "2"
    interval            = "5"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }

  tags = var.common_tags
}

data "template_file" "userdata_script" {
  template = file("userdata.tpl")
  vars = {
    git_url    = var.git_url
    AWS_REGION = var.aws_region
  }
}

/* Auto Scaling & Launch Configuration */
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "5.0.0"

  name = var.app_name
  tags = var.common_tags

  # Launch configuration creation
  lc_name                   = var.lc_name
  image_id                  = var.image_id
  security_groups           = [module.network.aws_security_groups.web.id]
  instance_type             = "t3a.small"
  iam_instance_profile_name = aws_iam_instance_profile.dam_ec2_profile.name
  user_data                 = data.template_file.userdata_script.rendered
  use_lc                    = true
  create_lc                 = true

  root_block_device = [
    {
      volume_size = "10"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group creation
  vpc_zone_identifier       = module.network.aws_subnet_ids.app.ids
  health_check_type         = "ELB"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_grace_period = 500
  target_group_arns         = [aws_alb_target_group.app.arn]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }
}

resource "aws_lb_listener_rule" "host_based_weighted_routing" {
  listener_arn = data.aws_alb_listener.web.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }

  condition {
    host_header {
      values = [for sn in var.service_names : "${sn}.*"]
    }
  }
}

resource "aws_s3_bucket" "dam_s3_bucket" {
  bucket = "bcparks-dam-${var.target_env}-images"
}

resource "aws_iam_policy" "s3_policy" {
	name        = "BCParks-Dam-S3-Access"
	path        = "/"
  description = "Allow access S3 bucket bcparks-dam-${var.target_env}-images"
	policy      = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": ["s3:ListBucket"],
          "Resource": ["arn:aws:s3:::bcparks-dam-${var.target_env}-images"]
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:GetObjectAttributes"
          ],
          "Resource": ["arn:aws:s3:::bcparks-dam-${var.target_env}-images/*"]
        }
      ]
    }
  )
}

resource "aws_iam_role" "ec2_role" {
  name               = "BCParks-Dam-EC2-Role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "dam_ec2_profile" {
  name = "BCParks-Dam-EC2-ip"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_policy_attachment" "dam_ec2_attach" {
  name       = "dam-s3-policy-attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.s3_policy.arn
}

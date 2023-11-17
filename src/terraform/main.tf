# main.tf

provider "aws" {
  region = var.aws_region
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
  name                 = "bcparks-dam-vm"
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
    unhealthy_threshold = "10"
  }

  tags = var.common_tags
}

data "template_file" "userdata_script" {
  template = file("userdata.tpl")
  vars = {
    git_url          = var.git_url
    target_env       = var.target_env
    aws_region       = var.aws_region
    rds_endpoint     = aws_rds_cluster.mysql.endpoint
    efs_dns_name     = aws_efs_file_system.efs_filestore.dns_name
    mysql_username   = local.secrets.mysql_username
    mysql_password   = local.secrets.mysql_password
    email_notify     = local.secrets.email_notify
    email_from       = local.secrets.email_from
    spider_password  = local.secrets.spider_password
    scramble_key     = local.secrets.scramble_key
    api_scramble_key = local.secrets.api_scramble_key
  }
}

/* Auto Scaling & Launch Configuration */
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "5.0.0"

  name = "bcparks-dam-vm"
  tags = var.common_tags

  # Launch configuration creation
  lc_name                   = var.lc_name
  image_id                  = var.image_id
  security_groups           = [module.network.aws_security_groups.web.id]
  instance_type             = (var.target_env != "prod" ? "t3a.micro" : "t3a.small")
  iam_instance_profile_name = aws_iam_instance_profile.ec2_profile.name
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

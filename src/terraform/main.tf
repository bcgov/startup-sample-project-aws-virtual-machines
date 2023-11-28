provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Gather VPC information from the network module

module "network" {
  source      = "git::https://github.com/BCDevOps/terraform-octk-aws-sea-network-info.git//?ref=master"
  environment = var.target_env
}

# S3 bucket for static assets

resource "aws_s3_bucket" "site" {
  bucket        = "${var.app_name}-site-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  force_destroy = true
}

# CloudFront distribution for the S3 bucket
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.app_name} site."
}

resource "aws_s3_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.site.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "AWS" : "${aws_cloudfront_origin_access_identity.oai.iam_arn}"
        },
        Action   = "s3:GetObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.site.bucket}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribution for ${var.app_name} site."
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.site.bucket

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.site.bucket

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.app_name}-distribution"
  }
}

/* Dynamo DB Table */
resource "aws_dynamodb_table" "ssp-greetings" {
  name      = "${var.app_name}-greetings"
  hash_key  = "id"
  range_key = "createdAt"

  # billing_mode   = "PAY_PER_REQUEST"
  read_capacity  = 20
  write_capacity = 20
  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }
}

# API Gateway

resource "aws_apigatewayv2_vpc_link" "app" {
  name               = var.app_name
  subnet_ids         = module.network.aws_subnet_ids.web.ids
  security_group_ids = [module.network.aws_security_groups.web.id]
}

resource "aws_apigatewayv2_api" "app" {
  name          = var.app_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "app" {
  api_id             = aws_apigatewayv2_api.app.id
  integration_type   = "HTTP_PROXY"
  connection_id      = aws_apigatewayv2_vpc_link.app.id
  connection_type    = "VPC_LINK"
  integration_method = "ANY"
  integration_uri    = aws_alb_listener.internal.arn
}

resource "aws_apigatewayv2_route" "app" {
  api_id    = aws_apigatewayv2_api.app.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_stage" "app" {
  api_id      = aws_apigatewayv2_api.app.id
  name        = "$default"
  auto_deploy = true
}

# Internal ALB 

resource "aws_alb" "app" {

  name                             = var.app_name
  internal                         = true
  subnets                          = module.network.aws_subnet_ids.web.ids
  security_groups                  = [module.network.aws_security_groups.web.id]
  enable_cross_zone_load_balancing = true

  lifecycle {
    ignore_changes = [access_logs]
  }
}

resource "aws_alb_listener" "internal" {
  load_balancer_arn = aws_alb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }
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
}

data "template_file" "userdata_script" {
  template = file("userdata.tpl")
  vars = {
    git_url    = var.git_url
    sha        = var.sha
    DB_NAME    = aws_dynamodb_table.ssp-greetings.id
    branch     = var.branch
    AWS_REGION = var.aws_region
  }
}

/* Auto Scaling & Launch Configuration */
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "5.0.0"

  name = var.app_name

  # Launch configuration creation
  lc_name                   = var.lc_name
  image_id                  = var.iamge_id
  instance_type             = "t2.micro"
  spot_price                = "0.0038"
  security_groups           = [module.network.aws_security_groups.app.id]
  iam_instance_profile_name = var.app_name
  user_data                 = data.template_file.userdata_script.rendered
  use_lc                    = true
  create_lc                 = true

  root_block_device = [
    {
      volume_size = "50"
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

resource "aws_iam_instance_profile" "ssp_profile" {
  name = var.app_name
  role = aws_iam_role.ssp-db.name
}

resource "aws_iam_role" "ssp-db" {
  name               = var.app_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "db_ssp" {
  name = var.app_name

  description = "policy to give dybamodb permissions to ec2"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DynamoDB",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:UpdateTable",
          "dynamodb:Scan"
        ],
        "Resource" : "*"
      },

      {
        "Resource" : "*",
        "Effect" : "Allow",
        "Action" : [
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter"
        ],
        "Resource" : "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ds:CreateComputer",
          "ds:DescribeDirectories"
        ],
        "Resource" : "*"
      }


    ]
  })
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.ssp-db.name
  policy_arn = aws_iam_policy.db_ssp.arn

}

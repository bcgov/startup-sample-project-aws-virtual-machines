# security.tf

resource "aws_iam_role" "ec2_role" {
  name               = "BCParks-Dam-EC2-Role"
  tags               = var.common_tags
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

resource "aws_security_group" "rds_security_group" {
  name        = "BCParks_RDS_sg"
  description = "allow inbound access from the web VMs"
  vpc_id      = module.network.aws_vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [module.network.aws_security_groups.web.id]
    description     = "For enabling RDS access"
  }

  egress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [module.network.aws_security_groups.web.id]
    description     = "For enabling RDS access"
  }

  tags = var.common_tags
}

resource "aws_security_group" "efs_security_group" {
  name        = "BCParks_EFS_sg"
  description = "allow inbound access from the web VMs"
  vpc_id      = module.network.aws_vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = [module.network.aws_security_groups.web.id]
    description     = "For enabling EFS access"
  }

  egress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = [module.network.aws_security_groups.web.id]
    description     = "For enabling EFS access"
  }

  tags = var.common_tags
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "BCParks-Dam-EC2-ip"
  role = aws_iam_role.ec2_role.name
  tags = var.common_tags
}

# Attachment for BCParks-Dam-S3-Access
resource "aws_iam_policy_attachment" "ec2_s3_attach" {
  name       = "dam-s3-policy-attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.s3_policy.arn
}

# Attachment for BCParks-Dam-EFS-Access
resource "aws_iam_policy_attachment" "ec2_efs_attach" {
  name       = "dam-efs-policy-attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.efs_policy.arn
}

# Attachment for AmazonSSMDirectoryServiceAccess
resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}

# Attachment for AmazonSSMManagedInstanceCore
resource "aws_iam_role_policy_attachment" "ec2_ssm_core_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attachment for CloudWatchAgentServerPolicy
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attachment for the custom policy PBMMAccel-SSMWriteAccessPolicy-xxxxxxxx
#   Services
#      KMS: Limited: Read, Write
#      S3:  Limited: Read, Permissions management, Write
#resource "aws_iam_role_policy_attachment" "ec2_custom_ssm_write_attach" {
#  role       = aws_iam_role.ec2_role.name
#  policy_arn = "arn:aws:iam::093135233083:policy/PBMMAccel-SSMWriteAccessPolicy-143CA3D7" # for DEV
#  policy_arn = "arn:aws:iam::739959981576:policy/PBMMAccel-SSMWriteAccessPolicy-4F6F3B76" # for TEST
#}


resource "aws_efs_file_system_policy" "efs_policy" {
  file_system_id = aws_efs_file_system.efs_filestore.id
  bypass_policy_lockout_safety_check = true
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "ExamplePolicy01",
    "Statement": [
        {            
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.ec2_role.arn}"
            },
            "Resource": "${aws_efs_file_system.efs_filestore.arn}",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite",
                "elasticfilesystem:ClientRootAccess"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        }
    ]
}
POLICY
  depends_on = [
    aws_iam_role.ec2_role,
    aws_efs_file_system.efs_filestore
  ]
}

resource "aws_iam_policy" "s3_policy" {
	name        = "BCParks-Dam-S3-Access"
	path        = "/"
  description = "Allow access S3 bucket bcparks-dam-${var.target_env}-backup"
  tags        = var.common_tags
	policy      = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": ["s3:ListBucket"],
          "Resource": ["arn:aws:s3:::bcparks-dam-${var.target_env}-backup"]
        },
        {
          "Effect": "Allow",
          "Action": ["s3:*"],
          "Resource": ["arn:aws:s3:::bcparks-dam-${var.target_env}-backup/*"]
        }
      ]
    }
  )
}
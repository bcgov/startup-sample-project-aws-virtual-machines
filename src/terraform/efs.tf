resource "aws_efs_file_system" "efs_filestore" {
  creation_token                  = "resourcespace-filestore"
  encrypted                       = true
  performance_mode                = "generalPurpose"
  throughput_mode                 = "bursting"

  tags = merge(
    {
        Name        = "ResourceSpace filestore"
    },
    var.common_tags
  )
}

resource "aws_iam_policy" "efs_policy" {
  name = "BCParks-Dam-EFS-Access"
  path        = "/"
  description = "Allow access EFS"
    tags        = var.common_tags
	policy      = jsonencode(
    {
    "Version": "2012-10-17",
    "Statement": [
      {
          "Effect": "Allow",
          "Action": [
             "elasticfilesystem:ClientMount",
             "elasticfilesystem:ClientWrite",
             "elasticfilesystem:ClientRootAccess"
          ],
          "Resource": "*",
          "Condition": {
            "StringEquals": {
              "aws:TagKeys/Name": "bcparks-dam-vm"
            }
          }
        }
      ]
    }
  )
}

resource "aws_efs_mount_target" "data_azA" {
  file_system_id  = aws_efs_file_system.efs_filestore.id
  subnet_id       = sort(module.network.aws_subnet_ids.data.ids)[0]
  security_groups = [aws_security_group.efs_security_group.id]
}

resource "aws_efs_mount_target" "data_azB" {
  file_system_id  = aws_efs_file_system.efs_filestore.id
  subnet_id       = sort(module.network.aws_subnet_ids.data.ids)[1]
  security_groups = [aws_security_group.efs_security_group.id]
}

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
}

resource "aws_efs_access_point" "filestore" {
  file_system_id = aws_efs_file_system.efs_filestore.id
  posix_user {
      uid  = "1000"
      gid = "1"
  }
  root_directory {
      creation_info {
          owner_gid   = "1"
          owner_uid   = "1000"
          permissions = "0775"
      }
      path = "/"
  }
  tags = merge(
    {
        Name        = "filestore"
    },
    var.common_tags
  )
}

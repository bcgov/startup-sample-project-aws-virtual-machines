# s3.tf

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "bcparks-dam-${var.target_env}-backup"
  tags   = var.common_tags
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

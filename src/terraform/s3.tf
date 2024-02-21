# s3.tf

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "bcparks-dam-${var.target_env}-backup"
  tags   = var.common_tags
}

### cloudwatch resources###
resource "aws_cloudwatch_dashboard" "main" {

  dashboard_name = var.cloudwatch.dashboard_name
  dashboard_body = var.cloudwatch.dashboard_body
}

resource "aws_cloudwatch_log_group" "log_group" {

  name              = var.cloudwatch.log_group
  retention_in_days = var.cloudwatch.retention_in_days
}



### cloudtrail resources ###
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "s3_encryption" {
  description             = var.kms_key_s3.description
  deletion_window_in_days = var.kms_key_s3.deletion_window_in_days
  enable_key_rotation     = var.kms_key_s3.enable_key_rotation
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = var.kms_key_s3.bucket
  force_destroy     = var.kms_key_s3.force_destroy # true
 }

 resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    object_ownership = var.kms_key_s3.object_ownership   #"BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.example]

  bucket = aws_s3_bucket.cloudtrail_bucket.id
  acl    = var.kms_key_s3.acl #"private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption.arn
      sse_algorithm     = var.kms_key_s3.sse_algorithm #"aws:kms"
    }
  }
}


resource "aws_s3_bucket_policy" "example_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.arn

  policy = templatefile(var.template_file_path, {
    bucket_arn = aws_s3_bucket.cloudtrail_bucket.arn
    account_id = data.aws_caller_identity.current.account_id
  })
}

resource "aws_cloudtrail" "example_trail" {
  name                          = var.kms_key_s3.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  s3_key_prefix                 = var.kms_key_s3.s3_key_prefix # "cloudtrail"
  enable_logging                = var.kms_key_s3.enable_logging #true
}


/*
resource "aws_s3_bucket" "example_bucket" {
  bucket = var.kms_key_s3.bucket
  acl               = var.kms_key_s3.acl 
  force_destroy     = true
  policy            = var.kms_key_s3.policy

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3_encryption.arn
        sse_algorithm     = var.kms_key_s3.sse_algorithm
      }
    }
  }
}

*/
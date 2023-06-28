terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_cognito_user_pool" "Project6AppUserPool" {
  name = var.user_pool_name

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_numbers = true
    require_symbols = true
    require_uppercase = true
  }

}

resource "aws_cognito_user_pool_client" "webapp" {
  name = "webapp"

  user_pool_id = aws_cognito_user_pool.Project6AppUserPool.id
}


resource "aws_s3_bucket" "images" {
  bucket = "images-bucket-project6"

  tags = {
    Name        = "Project 6 Images Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_cors_configuration" "images_bucket_cors_conf" {
  bucket = aws_s3_bucket.images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["https://s3-website-test.hashicorp.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_ownership_controls" "images_bucket_ownership_controls" {
  bucket = aws_s3_bucket.images.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "images_bucket_public_access_block" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "images_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.images_bucket_ownership_controls,
    aws_s3_bucket_public_access_block.images_bucket_public_access_block
  ]

  bucket = aws_s3_bucket.images.id
  acl    = "private"
}

resource "aws_iam_role" "Project6AppRole" {
  name = "Project6AppRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "Project 6 App Role"
    Environment = "Dev"
  }
}

resource "aws_iam_role_policy_attachment" "Project6AppRoleAttachment" {
  role       = aws_iam_role.Project6AppRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_policy" "project6_app_policy" {
  name        = "Project6AppPolicy"
  description = "Custom IAM policy for S3 bucket access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
       "arn:aws:s3:::${aws_s3_bucket.images.id}/*"
      ]
    }
  ]
}
EOF
}
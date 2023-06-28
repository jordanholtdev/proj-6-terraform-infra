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


resource "aws_s3_bucket_policy" "image_bucket_policy" {
  bucket = aws_s3_bucket.images.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.images.id}/*"
      ]
    }
  ]
}
EOF
}
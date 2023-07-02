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

# S3 Bucket for images and CORS configuration
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
    allowed_origins = ["https://s3-website-test.hashicorp.com", "http://localhost:5173"]
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

# IAM Role for the application
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

# AWS SQS Queue for image processing messages and policy
resource "aws_sqs_queue" "image_processing_queue" {
  name = "image-processing-queue"

  tags = {
    Name        = "Project 6 Image Processing Queue"
    Environment = "Dev"
  }
}

resource "aws_sqs_queue_policy" "image_processing_queue_policy" {
  queue_url = aws_sqs_queue.image_processing_queue.id

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "*"
        },
        "Action": "sqs:SendMessage",
        "Resource": "${aws_sqs_queue.image_processing_queue.arn}"
      }
    ]
  }
  EOF
}

# S3 bucket containing Lambda function to process images
resource "aws_s3_bucket" "project6-lambda-functions" {
  bucket = "project6-lambda-functions"  # Replace with your desired bucket name

  lifecycle {
    prevent_destroy = true  # Optional: Prevent accidental deletion
  }
  tags = {
    Name        = "Project 6 Lambda Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket_ownership_controls" {
  bucket = aws_s3_bucket.project6-lambda-functions.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_bucket_public_access_block" {
  bucket = aws_s3_bucket.project6-lambda-functions.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "lambda_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.lambda_bucket_ownership_controls,
    aws_s3_bucket_public_access_block.lambda_bucket_public_access_block
  ]

  bucket = aws_s3_bucket.project6-lambda-functions.id
  acl    = "private"
}


# Lambda function to process images
resource "aws_lambda_function" "image_processing_lambda" {
  function_name    = "image-processing-lambda"
  runtime          = "nodejs16.x"
  handler          = "index.handler"
  role             = aws_iam_role.project6_lambda_role.arn
  timeout          = 30
  memory_size      = 256

  # Replace with the S3 bucket containing your Lambda function code
  s3_bucket        = "project6-lambda-functions"
  s3_key           = "image-processing-lambda.zip"

  tags = {
    Name        = "Project 6 Image Processing Lambda"
    Environment = "Dev"
  }
}

# Lambda role
resource "aws_iam_role" "project6_lambda_role" {
  name = "project6_lambda_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "Project 6 Lambda Role"
    Environment = "Dev"
  }
}

resource "aws_iam_policy" "project6_lambda_policy" {
  name        = "project6_lambda_policy"
  description = "Policy for Lambda function to access SQS queue"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sqs:ReceiveMessage",
        Resource = aws_sqs_queue.image_processing_queue.arn
      }
    ]
  })
}

# Lambda role policy attachment
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.project6_lambda_role.name
  policy_arn = aws_iam_policy.project6_lambda_policy.arn
}

# SQS source event mapping
resource "aws_lambda_event_source_mapping" "sqs_mapping" {
  event_source_arn = aws_sqs_queue.image_processing_queue.arn
  function_name    = aws_lambda_function.image_processing_lambda.function_name
  batch_size       = 10
}
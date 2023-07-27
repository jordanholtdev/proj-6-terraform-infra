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
  region = var.aws_region
}

resource "aws_cognito_user_pool" "Project6AppUserPool" {
  name = var.user_pool_name

  username_attributes = ["email"]

  mfa_configuration = "OFF"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_LINK"
    email_message_by_link = "Please click the link below to verify your email address. {##Click Here##}"
    email_subject_by_link = "Your verification link"
  }

  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_numbers = true
    require_symbols = true
    require_uppercase = true
  }

}

resource "aws_cognito_user_pool_domain" "Project6AppUserPoolDomain" {
  domain = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.Project6AppUserPool.id
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

# CloudWatch log group for Lambda function
resource "aws_cloudwatch_log_group" "image_processing_log_group" {
  name              = "/aws/lambda/image-processing-lambda"
  retention_in_days = 30

  tags = {
    Name        = "Project 6 Image Processing Log Group"
    Environment = "Dev"
  }
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

  environment {
    variables = {
      IMAGE_RESULTS_SQS_QUEUE_URL = var.IMAGE_RESULTS_SQS_QUEUE_URL
    }
  }

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
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility",
          "sqs:SendMessage",
          "sqs:SendMessageBatch",
          "s3:GetObject",
          "rekognition:DetectLabels",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "${aws_sqs_queue.image_processing_queue.arn}",
          "${aws_sqs_queue.image_processing_queue.arn}/*",
          "${aws_s3_bucket.images.arn}",
          "${aws_s3_bucket.images.arn}/*",
          "${aws_lambda_function.image_processing_lambda.arn}",
          "${aws_lambda_function.image_processing_lambda.arn}:$LATEST",
          "arn:aws:logs:*:*:*",
          "arn:aws:rekognition:*:*:*",
          "${aws_cloudwatch_log_group.image_processing_log_group.arn}",
          "*"
        ]
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

# Allow cloudwatch logs to be created
resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processing_lambda.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = aws_lambda_function.image_processing_lambda.arn
}

# SQS queue for the image processing results
resource "aws_sqs_queue" "image_processing_results_queue" {
  name = "image-processing-results-queue"

  tags = {
    Name        = "Project 6 Image Processing Results Queue"
    Environment = "Dev"
  }
}

resource "aws_sqs_queue_policy" "image_processing_results_queue_policy" {
  queue_url = aws_sqs_queue.image_processing_results_queue.id

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
        "Resource": "${aws_sqs_queue.image_processing_results_queue.arn}"
      }
    ]
  }
  EOF
}


# S3 bucket for the Dockerrun.aws.json file
resource "aws_s3_bucket" "project6-dockerrun" {
  bucket = "project6-dockerrun"  # Replace with your desired bucket name

  tags = {
    Name        = "Project 6 Dockerrun Bucket"
    Environment = "Dev"
  }
}

# S3 ownership controls
resource "aws_s3_bucket_ownership_controls" "dockerrun_bucket_ownership_controls" {
  bucket = aws_s3_bucket.project6-dockerrun.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


# S3 block public access
resource "aws_s3_bucket_public_access_block" "dockerrun_bucket_public_access_block" {
  bucket = aws_s3_bucket.project6-dockerrun.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket ACL
resource "aws_s3_bucket_acl" "dockerrun_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.dockerrun_bucket_ownership_controls,
    aws_s3_bucket_public_access_block.dockerrun_bucket_public_access_block
  ]

  bucket = aws_s3_bucket.project6-dockerrun.id
  acl    = "private"
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "dockerrun_bucket_policy" {
  bucket = aws_s3_bucket.project6-dockerrun.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublicRead"
        Effect = "Allow"
        Principal = {
          AWS = "${aws_iam_role.project6_beanstalk_service.arn}"
        }
        Action = [
         "s3:GetObject",
         "s3:PutObject",
         "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.project6-dockerrun.arn}/*"
        ]
      }
    ]
  })
}

# Beanstalk IAM role
resource "aws_iam_role" "project6_beanstalk_service" {
  name = "aws-elasticbeanstalk-service-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "Project 6 Beanstalk Service Role"
    Environment = "Dev"
  }
}

# Beanstalk IAM policy attachment
resource "aws_iam_role_policy_attachment" "project6_beanstalk_service_policy_attachment" {
  role       = aws_iam_role.project6_beanstalk_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}



# Beanstalk application for the web application
resource "aws_elastic_beanstalk_application" "project6_app" {
  name = "project6-app"
  description = "Project 6 App"

  # appversion lifecycle
  appversion_lifecycle {
    max_count = 5
    service_role = aws_iam_role.project6_beanstalk_service.arn
  }

  tags = {
    Name        = "Project 6 App"
    Environment = "Dev"
  }

}

# Beanstalk environment for the web application
resource "aws_elastic_beanstalk_environment" "project6_app_env" {
  name                = "project6-app-env"
  application         = aws_elastic_beanstalk_application.project6_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.9 running Docker"

  # setting
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.project6_vpc
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     =  var.project6_subnet_1
  }
}




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


# load balancer
resource "aws_lb" "project6_lb" {
  name               = "project6-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [var.project6_subnet_1, var.project6_subnet_2]

  // add other required properties

  tags = {
    Name = "project6-lb"
    Project = "project6"
  }
}

# load balancer target group
resource "aws_lb_target_group" "project6_target_group" {
  name     = "project6-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.project6_vpc

  // add other required properties
  target_type = "instance"

  tags = {
    Name = "project6-target-group"
    Project = "project6"
  }
}

# load balancer listener
resource "aws_lb_listener" "project6_listener" {
  load_balancer_arn = aws_lb.project6_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.project6_target_group.arn
    type             = "forward"
  }
}

# load balancer listener rule for the target group
resource "aws_lb_listener_rule" "project6_listener_rule" {
  listener_arn = aws_lb_listener.project6_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project6_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }

}

# Execution role for the ECS task
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "ECS Task Execution Role"
    Environment = "Dev"
  }
}

# Execution role policy for the ECS task
resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "ecs-task-execution-policy"
  description = "Policy for the ECS task execution role"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

  tags = {
    Name        = "ECS Task Execution Policy"
    Environment = "Dev"
    Project     = "Project 6"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}

# ecs instance Role
resource "aws_iam_role" "ecsInstanceRole" {
  name = "ecsInstanceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# ecs instance profile
resource "aws_iam_instance_profile" "ecsInstanceProfile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecsInstanceRole.name
}

resource "aws_iam_role_policy_attachment" "ecsInstanceRole_policy_attachment" {
  role       = aws_iam_role.ecsInstanceRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# ESC cluster
resource "aws_ecs_cluster" "project6_ecs_cluster" {
  name = "project6-ecs-cluster"

  tags = {
    Name        = "Project 6 ECS Cluster"
    Environment = "Dev"
  }
}

# Launch configuration for the ECS cluster
resource "aws_launch_configuration" "project6_launch_config" {
  image_id = "ami-06ca3ca175f37dd66"
  instance_type = "t2.micro"

  // add other required properties
  iam_instance_profile = aws_iam_instance_profile.ecsInstanceProfile.name // this is the name of the instance profile

  # Enable ECS
  user_data = <<EOF
                #!/bin/bash
                echo ECS_CLUSTER=${aws_ecs_cluster.project6_ecs_cluster.name} >> /etc/ecs/ecs.config
                EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Auto scaling group for the ECS cluster
resource "aws_autoscaling_group" "project6" {
  desired_capacity = 1
  launch_configuration = aws_launch_configuration.project6_launch_config.id
  max_size = 1
  min_size = 1
  vpc_zone_identifier = [var.project6_subnet_1, var.project6_subnet_2]

  tag {
    key = "Name"
    value = "Project 6 Auto Scaling Group"
    propagate_at_launch = true
  }
}


# Security group for the ECS cluster
resource "aws_security_group" "ecs_cluster_security_group" {
  name        = "ecs-cluster-security-group"
  description = "Security group for the ECS cluster"

  vpc_id = var.project6_vpc

  ingress {
    description = "Allow inbound traffic from the load balancer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS task definition
resource "aws_ecs_task_definition" "project6_task_definition" {
  family                   = "project6-task-definition"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.Project6AppRole.arn


  container_definitions = jsonencode([
    {
      name      = "project6"
      image     = "${var.ECR_REPOSITORY_URL}:${var.image_tag}"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 0
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/lambda/image-processing-lambda"
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  tags = {
    Name        = "Project 6 Task Definition"
    Environment = "Dev"
  }
}

# ECS Service
resource "aws_ecs_service" "project6_ecs_service" {
  name            = "project6-ecs-service"
  cluster         = aws_ecs_cluster.project6_ecs_cluster.id
  task_definition = aws_ecs_task_definition.project6_task_definition.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = [var.project6_subnet_1]
    security_groups = [aws_security_group.ecs_cluster_security_group.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.project6_target_group.arn
    container_name   = "project6"
    container_port   = 80
  }

  tags = {
    Name        = "Project 6 ECS Service"
    Environment = "Dev"
  }
}



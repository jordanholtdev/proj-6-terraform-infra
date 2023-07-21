output "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value = aws_cognito_user_pool.Project6AppUserPool.id
}

output "aws_s3_bucket_id" {
  description = "The ID of the S3 Bucket"
  value = aws_s3_bucket.images.id
}

output "aws_s3_bucket_arn" {
  description = "The ARN of the S3 Bucket"
  value = aws_s3_bucket.images.arn
}

output "image_processing_queue_id" {
  description = "The URL of the SQS Queue"
  value = aws_sqs_queue.image_processing_queue.id
}

output "image_processing_queue_arn" {
  description = "The ARN of the SQS Queue"
  value = aws_sqs_queue.image_processing_queue.arn
}

output "project6_lambda_role" {
  description = "The ARN of the IAM Role for the Lambda function"
  value = aws_iam_role.project6_lambda_role.arn
}

output "aws_s3_bucket_lambda_functions_id" {
  description = "The ID of the lambda function S3 bucket"
  value = aws_s3_bucket.project6-lambda-functions.id
}

output "project6_lambda_role_name" {
  description = "The name of the IAM Role for the Lambda function"
  value = aws_iam_role.project6_lambda_role.name
}

output "project6_lambda_policy_arn" {
  description = "The ARN of the IAM Policy for the Lambda function"
  value = aws_iam_policy.project6_lambda_policy.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value = aws_lambda_function.image_processing_lambda.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value = aws_lambda_function.image_processing_lambda.arn
}

output "image_processing_results_queue_id" {
  description = "The URL of the SQS Queue"
  value = aws_sqs_queue.image_processing_results_queue.id
}

output "image_processing_results_queue_arn" {
  description = "The ARN of the SQS Queue"
  value = aws_sqs_queue.image_processing_results_queue.arn
}

output "project6_ecs_cluster_id" {
  description = "The ID of the ECS Cluster"
  value = aws_ecs_cluster.project6_ecs_cluster.id
}

output "project6_task_definition_arn" {
  description = "The ARN of the ECS Task Definition"
  value = aws_ecs_task_definition.project6_task_definition.arn
}

output "ecs_cluster_security_group_id" {
  description = "The ID of the ECS Cluster Security Group"
  value = aws_security_group.ecs_cluster_security_group.id
}

output "Project6AppRole_arn" {
  description = "The ARN of the IAM Role for the ECS Task"
  value = aws_iam_role.Project6AppRole.arn
}

output "ecs_task_execution_role_name" {
  description = "The name of the IAM Role for the ECS Task"
  value = aws_iam_role.ecs_task_execution_role.name
}

output "ecs_task_execution_policy_arn" {
  description = "The ARN of the IAM Policy for the ECS Task"
  value = aws_iam_policy.ecs_task_execution_policy.arn
}

output "project6_target_group_arn" {
  description = "The ARN of the Target Group"
  value = aws_lb_target_group.project6_target_group.arn
}

output "project6_lb_arn" {
  description = "The ARN of the Load Balancer"
  value = aws_lb.project6_lb.arn
}

output "project6_listener_arn" {
  description = "The ARN of the Load Balancer Listener"
  value = aws_lb_listener.project6_listener.arn
}

output "project6_ecs_cluster" {
  description = "The name of the ECS Cluster"
  value = aws_ecs_cluster.project6_ecs_cluster.name
}

output "ecsInstanceRole_name" {
  description = "The name of the IAM Role for the ECS Instance"
  value = aws_iam_role.ecsInstanceRole.name
}

output "project6_launch_template_id" {
  description = "The ID of the Launch Template"
  value = aws_launch_template.project6_launch_template.id
}
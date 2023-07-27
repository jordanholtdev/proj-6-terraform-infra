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

output "beanstalk_application_name" {
  description = "The name of the Elastic Beanstalk application"
  value = aws_elastic_beanstalk_application.project6_app.name
}

output "project6_dockerrun_id" {
  description = "The ID of the Elastic Beanstalk application version"
  value = aws_s3_bucket.project6_dockerrun.id
}

output "beanstalk_service_name" {
  description = "The name of the Elastic Beanstalk service"
  value = aws_iam_role.beanstalk_service.name
}
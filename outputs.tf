output "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value = aws_cognito_user_pool.Project6AppUserPool.id
}

output "aws_s3_bucket_id" {
  description = "The ID of the S3 Bucket"
  value = aws_s3_bucket.images.id
}
# variable "user_pool_name" {
#   description = "Value of the Name for the Cognito User Pool"
#   type        = string
#   default     = "Project6AppUserPool4"
# }

# variable "user_pool_domain" {
#   description = "Value of the Domain for the Cognito User Pool"
#   type        = string
#   default     = "project6app"
# }

# variable "IMAGE_RESULTS_SQS_QUEUE_URL" {
#   description = "URL of the SQS queue"
#   type        = string
#   default     = ""
# }

# variable "ECR_REPOSITORY_URL" {
#   description = "URL of the ECR repository"
#   type        = string
#   default     = ""
# }

# variable "image_tag" {
#   description = "The tag of the Docker image to deploy"
#   type        = string
# }

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

# variable "project6_vpc" {
#   description = "The ID of the VPC"
#   type        = string
#   default     = ""
# }

# variable "project6_subnet_1" {
#   description = "value of the subnet 1"
#   type        = string
#   default     = ""
# }
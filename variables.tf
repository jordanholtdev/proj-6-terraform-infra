variable "user_pool_name" {
  description = "Value of the Name for the Cognito User Pool"
  type        = string
  default     = "Project6AppUserPool"
}

variable "IMAGE_RESULTS_SQS_QUEUE_URL" {
  description = "URL of the SQS queue"
  type        = string
  default     = ""
}
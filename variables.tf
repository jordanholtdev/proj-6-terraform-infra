variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "Project6AppServerInstance"
}

variable "instance_type" {
  description = "Type of EC2 instance to launch"
  type        = string
  default     = "t2.micro"
}

variable "ami" {
  description = "AMI to use for the EC2 instance"
  type        = string
  default     = "ami-026ebd4cfe2c043b2"
}
### Var
variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "eu-central-1"
}
variable "docker_image_tag" {
  description = "Docker image tag"
  default     = "latest"
}

variable "email_addresses" {
  description = "Email address to be verified with SES"
  type        = string
}

variable "iam_user_name" {
  description = "Name of the IAM user for SES SMTP credentials"
  type        = string
  default     = "ses-smtp-user"
}

variable "policy_ses_arn" {
  description = "Policy ARN to attach to the IAM user"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

variable "email_port" {
  description = "Email port"
  type        = string
  default     = "587"
}

variable "redis_port" {
  description = "Redis port"
  type        = string
  default     = "6379"
}

variable "redis_host" {
  description = "Redis host"
  type        = string
  default     = "localhost"
}

variable "redis_user" {
  description = "Redis user"
  type        = string
  default     = ""
}


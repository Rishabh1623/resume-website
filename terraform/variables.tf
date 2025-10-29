variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name for the website"
  type        = string
}

variable "contact_email" {
  description = "Email address for contact form notifications"
  type        = string
}

variable "use_existing_resources" {
  description = "Whether to use existing AWS resources (true) or create new ones (false)"
  type        = bool
  default     = true
}

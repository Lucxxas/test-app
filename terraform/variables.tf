
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "TP-FINAL"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "Password123!"
}

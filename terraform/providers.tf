terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # Credentials managed by Spacelift environment variables
  # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

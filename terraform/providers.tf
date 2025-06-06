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
  region     = "us-east-1"
  access_key = "ASIASJFXSSZBP7FQSLFQ"
  secret_key = "CVz3G2oxLCSlgmqoIOUiSVInDTBj3Gw3Onm884ea"
}

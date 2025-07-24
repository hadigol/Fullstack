terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

module "s3_cdn"{
    source = "../modules/s3_cdn"
    bucket_name = var.bucket_name
    tags = var.tags
}
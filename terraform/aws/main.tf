terraform {
    required_version = ">= 1.1" 

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">=4.55.0"
        }
    }

#     backend "pg" {
#         schema_name = "aws"
#     }
}

provider "aws" {
    region       = "eu-west-1"
    access_key = var.access_key
    secret_key = var.secret_key
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}
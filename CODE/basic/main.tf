terraform {
    required_providers {
          aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
          }
    }
}

# Configure the AWS Provider
provider "aws" {
    region = "ap-south-1"
}

resource "aws_instance" "example" {
  ami           = "ami-08188a5a4dfdbd573" # Ubuntu 20.04 LTS // us-east-1
  instance_type = "t3.micro"
}
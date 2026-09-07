terraform {
  backend "s3" {
    bucket = "terraform-aws-pratik-backend-bucket"
    key    = "terraform/remotestate"
    region = "ap-south-1"
  }
}

provider "aws" {
  profile = "default"
}

module "ec2" {
  source = "./modules/ec2"

  name          = "PSRemoteStateInstance"
  ami           = "ami-01a00762f46d584a1"
  instance_type = "t2.micro"

  tags = {
    Name        = "PSRemoteStateInstance"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.15"

  bucket = "terraform-aws-pratik-module-bucket"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }

  tags = {
    Name        = "PSModuleBucket"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "s3_bucket_id" {
  description = "The name of the S3 bucket created by the module"
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket created by the module"
  value       = module.s3_bucket.s3_bucket_arn
}

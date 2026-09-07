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

resource "aws_instance" "app_server" {
  ami           = "ami-01a00762f46d584a1"
  instance_type = "t2.micro"

  tags = {
    Name = "PSRemoteStateInstance"
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

# Configure Terraform and specify the required providers
terraform {
  # Define the providers required by this Terraform configuration
  required_providers {
    # Configure the AWS provider
    aws = {
      # Specify the provider source from the Terraform Registry
      source  = "hashicorp/aws"
      # Use AWS provider version 6.x
      version = "~> 6.0"
    }
  }
  # Specify the minimum Terraform CLI version required
  required_version = ">= 1.5.0"
}

# Configure the AWS provider
provider "aws" {
  # ap-south-1 = Asia Pacific (Singapore)
  region = "ap-southeast-1"
}

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "Bedrock-Knowledge-Base"
      Environment = "Lab"
      ManagedBy   = "Terraform"
    }
  }
}

# Signs requests to the OpenSearch Serverless data plane so Terraform can
# create the vector index inside the collection. OpenSearch Serverless requires
# SigV4-signed requests against the "aoss" service.
provider "opensearch" {
  url               = aws_opensearchserverless_collection.vector.collection_endpoint
  healthcheck       = false
  aws_region        = var.aws_region
  sign_aws_requests = true
}

resource "aws_s3_bucket" "documents" {
  bucket_prefix = "${var.project_name}-documents-"
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "aws" {
  bucket = aws_s3_bucket.documents.id
  key    = "aws.txt"
  source = "${path.module}/documents/aws.txt"
}

resource "aws_s3_object" "terraform" {
  bucket = aws_s3_bucket.documents.id
  key    = "terraform.txt"
  source = "${path.module}/documents/terraform.txt"
}

resource "aws_s3_object" "bedrock" {
  bucket = aws_s3_bucket.documents.id
  key    = "bedrock.txt"
  source = "${path.module}/documents/bedrock.txt"
}

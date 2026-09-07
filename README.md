# terraform-aws-training

Git connection Check

## Terraform Backend

This project uses an S3 bucket as the Terraform remote backend for storing state.

- **Backend S3 bucket:** `terraform-aws-pratik-backend-bucket`

### Example backend configuration

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-aws-pratik-backend-bucket"
    key    = "path/to/terraform.tfstate"
    region = "us-east-1"
  }
}
```

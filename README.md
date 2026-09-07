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
    key    = "terraform/remotestate"
    region = "ap-south-1"
  }
}
```

## Terraform Workspaces

This project uses two workspaces: `default` and `dev`.

### Common workspace commands

```bash
# List all workspaces (the active one is marked with *)
terraform workspace list

# Show the current workspace
terraform workspace show

# Switch to the dev workspace
terraform workspace select dev

# Switch back to the default workspace
terraform workspace select default
```

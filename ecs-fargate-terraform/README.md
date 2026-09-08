# Deploy ECS/Fargate Infrastructure Using Terraform

This lab deploys a simple containerized application on **AWS ECS Fargate** using Terraform. It runs a public **NGINX** image, so no Docker experience or custom image is required. You build real, working infrastructure (networking, load balancing, logging) using only Terraform and the AWS CLI.

## What This Lab Does

It provisions a complete, production-shaped setup for running containers without managing any servers:

- A **VPC** with 2 public and 2 private subnets across two Availability Zones
- An **Internet Gateway** (public inbound/outbound) and a **NAT Gateway** (private outbound-only)
- **Security groups** that allow only the traffic that's actually needed
- An **IAM execution role** so ECS can pull images and write logs
- An **ECS Fargate** cluster, task definition, and service running NGINX — no EC2 instances to manage
- An **Application Load Balancer (ALB)** in front of the tasks
- **CloudWatch Logs** for container output
- A private **ECR** repository (created for later use; the lab itself uses the public NGINX image)

### Architecture

```
                 Internet
                    │
                    ▼
        ┌───────────────────────┐
        │   Application Load     │   (public subnets, 2 AZs)
        │      Balancer (ALB)    │
        └───────────┬───────────┘
                    │  forwards HTTP :80
                    ▼
        ┌───────────────────────┐
        │   ECS Fargate tasks    │   (private subnets, 2 AZs)
        │      nginx:latest      │
        └───────────┬───────────┘
                    │  outbound only
                    ▼
             NAT Gateway ──► Internet (pull image, reach AWS APIs)
```

Users reach the app through the ALB in the public subnets. The ALB forwards traffic to Fargate tasks in the private subnets, which have no direct internet exposure. The tasks reach out only through the NAT Gateway to pull the image and talk to AWS services.

## Files

| File | Purpose |
|------|---------|
| `provider.tf` | Terraform + AWS provider configuration (`~> 6.0`) |
| `variables.tf` | Input variables (region, project name, VPC CIDR, container port, task count) |
| `vpc.tf` | VPC, subnets, Internet Gateway, NAT Gateway, route tables |
| `security-groups.tf` | ALB and ECS security groups |
| `ecr.tf` | Private ECR repository (ready for your own images later) |
| `iam.tf` | ECS task execution role |
| `alb.tf` | Application Load Balancer, target group, HTTP listener |
| `ecs.tf` | CloudWatch log group, ECS cluster, task definition, ECS service |
| `outputs.tf` | Useful outputs (ALB DNS, app URL, cluster/service names, etc.) |
| `terraform.tfvars` | Values for this lab (region, project name, task count) |

## Prerequisites

- **Terraform** >= 1.5.0 installed
- **AWS CLI** installed and configured with valid credentials (`aws configure`)
- Permissions to create VPC, ECS, ELB, IAM, ECR, and CloudWatch resources

## How to Deploy

Run these from inside the `ecs-fargate-terraform` folder:

```bash
# 1. Initialize providers and modules
terraform init

# 2. Format and validate the configuration
terraform fmt
terraform validate      # expect: "Success! The configuration is valid."

# 3. Review what will be created
terraform plan

# 4. Create the infrastructure (type "yes" when prompted)
terraform apply
```

`terraform apply` can take several minutes — the NAT Gateway, load balancer, and Fargate tasks all take time to become ready.

> **Region note:** `terraform.tfvars` defaults to `ap-south-1` (Mumbai). If you use a different region, update `aws_region` in `terraform.tfvars`.

## How to Verify the Resources Were Created

### 1. Test the application (quickest check)

```bash
# Get the public URL
terraform output application_url

# Open it in a browser, or curl it
curl $(terraform output -raw application_url)
```

You should see the **"Welcome to nginx!"** page. The `curl` output should contain `<title>Welcome to nginx!</title>`.

> It can take 30–60 seconds after apply finishes for both tasks to pass their first health check. If you get a connection error immediately, wait a minute and try again.

### 2. Check with Terraform outputs

```bash
terraform output
```

Confirms the ALB DNS name, application URL, VPC ID, ECS cluster name, ECS service name, and ECR repository URL.

### 3. Verify with the AWS CLI

```bash
# ECS service — check desired vs. running task count
aws ecs describe-services \
  --cluster ecs-fargate-demo-cluster \
  --services ecs-fargate-demo-service

# List the running tasks
aws ecs list-tasks \
  --cluster ecs-fargate-demo-cluster \
  --service-name ecs-fargate-demo-service
```

A healthy deployment shows `desiredCount` and `runningCount` matching (both `2` by default).

### 4. Verify in the AWS Console

| Service | Where to look | What "good" looks like |
|---------|---------------|------------------------|
| **ECS** | ECS → Clusters → `ecs-fargate-demo-cluster` → Services → `ecs-fargate-demo-service` | Running count matches desired count |
| **Load Balancer** | EC2 → Load Balancers → `ecs-fargate-demo-alb` | State is **Active** |
| **Target Group** | EC2 → Target Groups → `ecs-fargate-demo-tg` → Targets | Both targets show **Healthy** |
| **CloudWatch** | CloudWatch → Logs → Log groups → `/ecs/ecs-fargate-demo` | Log streams from the running tasks |
| **VPC** | VPC → Your VPCs → `ecs-fargate-demo-vpc` | VPC plus 2 public + 2 private subnets |

## Scale the Service (optional)

Change `desired_count` in `terraform.tfvars`:

```hcl
desired_count = 3
```

Then re-apply:

```bash
terraform plan
terraform apply
```

Re-check with `aws ecs describe-services ...` — you should now see `desiredCount = 3` and `runningCount = 3`, with no servers to provision or patch.

## Clean Up (Important)

The **NAT Gateway** and **load balancer** are billed by the hour. Destroy everything as soon as you're done:

```bash
terraform destroy
```

Type `yes` when prompted. Terraform removes every resource it created, including the VPC. Confirm in the console under ECS, EC2 → Load Balancers, ECR, CloudWatch, VPC, and IAM.

## Troubleshooting

| Problem | Likely cause / check |
|---------|----------------------|
| ECS tasks stay in `PENDING` | Check `aws ecs describe-services ...` events. Common causes: misconfigured security group, private route table missing the NAT route, image can't be pulled, or a task definition error. |
| ALB returns `503` | Targets are unhealthy. Confirm the ECS security group allows the container port from the ALB security group. |
| Tasks can't pull the image | Confirm the private route table has a `0.0.0.0/0` route pointing at the NAT Gateway. Without it, private tasks can't reach the internet. |

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.app.name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "load_balancer_dns" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.app.dns_name
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_lb.app.dns_name}"
}

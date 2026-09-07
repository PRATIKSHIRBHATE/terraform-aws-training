output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.ec2_instance.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = module.ec2_instance.arn
}

output "public_ip" {
  description = "The public IP address assigned to the instance, if applicable"
  value       = module.ec2_instance.public_ip
}

output "private_ip" {
  description = "The private IP address assigned to the instance"
  value       = module.ec2_instance.private_ip
}

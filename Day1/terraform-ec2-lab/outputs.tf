output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of EC2 instance"
  value       = aws_instance.web_server.public_dns
}

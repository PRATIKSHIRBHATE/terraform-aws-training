variable "name" {
  description = "Name to be used on the EC2 instance created"
  type        = string
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t2.micro"
}

variable "ami" {
  description = "ID of AMI to use for the instance. If null, the module falls back to its default Amazon Linux 2023 SSM parameter."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch the instance in. If null, AWS uses the default subnet."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Key pair name to use for SSH access to the instance"
  type        = string
  default     = null
}

variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the instance"
  type        = map(string)
  default     = {}
}

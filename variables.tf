variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bastion_instance_type" {
  description = "Instance type for the Bastion host"
  type        = string
  default     = "t3.micro"
}

variable "web_instance_type" {
  description = "Instance type for the Web servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for the Database server"
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "The name of the SSH key pair to use for instances"
  type        = string
  default     = "terraform_kp"
}

variable "my_ip" {
  description = "Your current public IP address for SSH access"
  type        = string
  default     = "102.89.75.245"
} 
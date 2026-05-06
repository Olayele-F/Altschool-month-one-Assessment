output "vpc_id" {
  value       = aws_vpc.techcorp_vpc.id
  description = "The ID of the TechCorp VPC"
}

output "alb_dns_name" {
  value       = aws_lb.techcorp_alb.dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "bastion_public_ip" {
  value       = aws_eip.bastion_eip.public_ip
  description = "The Elastic IP address of the Bastion Host"
}
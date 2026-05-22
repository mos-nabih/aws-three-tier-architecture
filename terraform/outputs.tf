output "vpc_id" {
  description = "ID of the project VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for the presentation tier."
  value       = aws_subnet.public[*].id
}

output "app_private_subnet_ids" {
  description = "Private subnet IDs for the application tier."
  value       = aws_subnet.app_private[*].id
}

output "data_private_subnet_ids" {
  description = "Private subnet IDs for the data tier."
  value       = aws_subnet.data_private[*].id
}

output "availability_zones" {
  description = "Availability Zones used by this deployment."
  value       = local.availability_zones
}

output "alb_security_group_id" {
  description = "Security group ID for the presentation tier load balancer."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID for the application tier."
  value       = aws_security_group.app.id
}

output "data_security_group_id" {
  description = "Security group ID for the data tier."
  value       = aws_security_group.data.id
}

output "alb_dns_name" {
  description = "DNS name of the internet-facing Application Load Balancer."
  value       = aws_lb.app.dns_name
}

output "app_target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.app.arn
}

output "app_instance_ids" {
  description = "Instance IDs for the application tier EC2 instances."
  value       = aws_instance.app[*].id
}

output "database_instance_id" {
  description = "Instance ID for the data tier placeholder."
  value       = aws_instance.database.id
}

output "database_private_ip" {
  description = "Private IP address for the data tier placeholder."
  value       = aws_instance.database.private_ip
}

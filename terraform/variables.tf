variable "aws_region" {
  description = "AWS region where the project infrastructure will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the project VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "database_port" {
  description = "Port used by the data tier. The starter project uses PostgreSQL-style port 5432."
  type        = number
  default     = 5432
}

variable "app_instance_type" {
  description = "EC2 instance type for the application tier."
  type        = string
  default     = "t3.micro"
}

variable "app_instance_count" {
  description = "Number of EC2 instances in the application tier."
  type        = number
  default     = 3
}

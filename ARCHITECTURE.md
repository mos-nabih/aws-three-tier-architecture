# Architecture Documentation

## Overview

This project implements a three tier architecture on AWS:

- Presentation tier: Application Load Balancer in public subnets
- Application tier: EC2 instances in private subnets
- Data tier: EC2 database placeholder in isolated private subnets

The design separates public access, application processing, and data access
using subnet placement, route tables, and security groups.

## Components

### VPC

- Name: `three-tier-vpc`
- CIDR: `10.0.0.0/16`
- Region: `us-east-1`
- Availability Zones: `us-east-1a`, `us-east-1b`
- DNS support: enabled
- DNS hostnames: enabled

### Subnets

Public presentation subnets:

- `public-subnet-1`: `10.0.1.0/24`, `us-east-1a`
- `public-subnet-2`: `10.0.2.0/24`, `us-east-1b`

Private application subnets:

- `app-private-subnet-1`: `10.0.11.0/24`, `us-east-1a`
- `app-private-subnet-2`: `10.0.12.0/24`, `us-east-1b`

Private data subnets:

- `data-private-subnet-1`: `10.0.21.0/24`, `us-east-1a`
- `data-private-subnet-2`: `10.0.22.0/24`, `us-east-1b`

### Application Load Balancer

- Type: Application Load Balancer
- Scheme: internet facing
- Subnets: public subnets across two AZs
- Listener: HTTP port `80`
- Target group protocol: HTTP
- Target group port: `80`
- Health check path: `/health`

### Application Instances

- Count: 3
- Instance type: `t3.micro`
- AMI: latest Amazon Linux 2023 x86_64 AMI
- Placement: private application subnets
- Public IP: disabled
- Root volume: 8 GB encrypted gp3
- Metadata: IMDSv2 required

The application returns an HTML page containing:

- instance ID
- private IP address
- Availability Zone
- database connection status
- database host and port
- health check path

The `/health` endpoint returns a plain `ok` response for the ALB health check.

### Data Placeholder

- Count: 1
- Instance type: `t3.micro`
- Placement: first data private subnet
- Public IP: disabled
- Root volume: 8 GB encrypted gp3
- Service: simple Python TCP listener on port `5432`

## Network Design Rationale

The VPC uses a `/16` CIDR block to provide room for tier separation and future
growth. Each subnet uses a `/24`, which is simple to reason about and leaves
additional address space available.

The public tier has a route to the Internet Gateway because the ALB must accept
internet traffic.

The application tier has a route to the NAT Gateway so private instances can
initiate outbound internet traffic without receiving public IP addresses.

The data tier has no default internet route. It can communicate locally inside
the VPC, but it cannot reach the public internet directly.

## Security Strategy

Security is enforced with security groups for each tier:

- ALB security group allows HTTP and HTTPS from the internet.
- App security group allows HTTP and HTTPS only from the ALB security group.
- Data security group allows database traffic only from the App security group.

Private instances have no public IP addresses. The data tier route table has no
NAT Gateway or Internet Gateway route.

## High Availability Approach

The design uses two Availability Zones for public, application, and data
subnets.

High availability features currently included:

- ALB deployed across two public subnets
- App instances distributed across two private application subnets
- Target group health checks on `/health`

Current trade-off:

- Only one NAT Gateway is used to reduce cost.
- The database placeholder is a single EC2 instance and is not highly available.

Production improvements would include:

- one NAT Gateway per AZ
- Auto Scaling Group for the application tier
- RDS across multiple Availability Zones instead of the EC2 database placeholder
- backups and restore testing

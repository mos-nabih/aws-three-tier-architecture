# Security Documentation

## Security Group Rules

### ALB Security Group

Name: `alb-sg`

Inbound:

| Protocol | Port | Source | Purpose |
|---|---:|---|---|
| TCP | 80 | `0.0.0.0/0` | Public HTTP access |
| TCP | 443 | `0.0.0.0/0` | Public HTTPS allowance |

Outbound:

| Protocol | Port | Destination | Purpose |
|---|---:|---|---|
| TCP | 80 | App SG | Forward traffic to app instances |

### Application Security Group

Name: `app-sg`

Inbound:

| Protocol | Port | Source | Purpose |
|---|---:|---|---|
| TCP | 80 | ALB SG | HTTP from load balancer |
| TCP | 443 | ALB SG | HTTPS from load balancer if enabled later |

Outbound:

| Protocol | Port | Destination | Purpose |
|---|---:|---|---|
| TCP | 80 | `0.0.0.0/0` | Package downloads through NAT |
| TCP | 443 | `0.0.0.0/0` | HTTPS outbound access through NAT |
| TCP | 5432 | Data SG | Database connectivity |

### Data Security Group

Name: `data-sg`

Inbound:

| Protocol | Port | Source | Purpose |
|---|---:|---|---|
| TCP | 5432 | App SG | Database traffic from app tier |

Outbound:

No explicit outbound rules are configured.

## Network Isolation Strategy

The architecture uses subnet placement and route tables to isolate tiers:

- Public subnets route internet traffic through the Internet Gateway.
- Application private subnets use the NAT Gateway for outbound only internet access.
- Data private subnets do not have a default route to the internet.

Private EC2 instances do not receive public IP addresses. The ALB is the only
internet facing entry point.

## IAM Roles And Policies

No custom IAM roles are currently attached to the EC2 instances.

This is acceptable for the current project because the application does not call
AWS APIs. If application instances later need access to AWS services, use an IAM
role with least privilege permissions instead of static credentials.

Recommended future IAM additions:

- EC2 instance role for CloudWatch Agent logs and metrics
- SSM role for Session Manager access instead of SSH
- Separate Terraform deployment identity with least privilege permissions

## Security Best Practices Applied

- No public IP addresses on application or data instances
- ALB is the only public entry point
- Security group references are used instead of broad private CIDR rules
- Data tier accepts traffic only from the application security group
- Data tier has no direct internet route
- EC2 root volumes are encrypted
- IMDSv2 is required on EC2 instances for accessing metadata
- SSH access is not opened

## Potential Vulnerabilities And Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| ALB currently allows HTTP | Traffic is not encrypted in transit from client to ALB | Add ACM certificate and HTTPS listener |
| App instances can make outbound HTTP and HTTPS requests | A compromised app instance could reach external sites through the NAT Gateway | Limit outbound access to only what the app needs in a production setup |
| Single NAT Gateway | AZ dependency for private outbound traffic | Use one NAT Gateway per AZ in production |
| Single EC2 database placeholder | No data durability or HA | Replace with RDS across multiple Availability Zones |
| No centralized logs | Harder investigation after incidents | Add CloudWatch logs and ALB access logs |
| No AWS WAF on the load balancer | The app has less protection from common web attacks like SQL injection | Add AWS WAF rules to the ALB in a production setup |
| No secrets manager integration | Future DB credentials could be mishandled | Store DB credentials in AWS Secrets Manager |

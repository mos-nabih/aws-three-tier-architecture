# Improvements

## Short Term Improvements: 0 to 3 Months

- Add HTTPS listener with AWS Certificate Manager.
- Redirect HTTP to HTTPS.
- Add CloudWatch logs for app instances.
- Add ALB access logs to S3.
- Add a simple CI check for `terraform fmt` and `terraform validate`.
- Replace the EC2 database placeholder with RDS for a more realistic data tier.

## Long Term Improvements: 3 to 12 Months

- Use RDS across multiple Availability Zones with automated backups.
- Add AWS WAF in front of the ALB.
- Add Route 53 DNS and a custom domain.
- Add blue/green or rolling deployments.
- Add CloudWatch dashboards and alarms.
- Add one NAT Gateway per AZ for production HA.
- Add centralized secrets management with AWS Secrets Manager.
- Add remote Terraform state with S3 and DynamoDB locking.
- Split Terraform into reusable modules.

## Production Readiness Checklist

- [ ] HTTPS enabled
- [ ] HTTP redirects to HTTPS
- [ ] WAF enabled
- [ ] ALB access logs enabled
- [ ] App logs shipped to CloudWatch
- [ ] Alarms configured for ALB 5xx, target health, CPU, memory, and disk
- [ ] App tier uses Auto Scaling Group
- [ ] Database uses RDS across multiple Availability Zones
- [ ] Database backups enabled
- [ ] Backup restore tested
- [ ] Secrets stored in Secrets Manager
- [ ] EC2 access through SSM Session Manager
- [ ] Terraform remote state configured
- [ ] Least privilege IAM roles configured
- [ ] Runbook created for incident response
- [ ] Cost budget and billing alerts configured

## Disaster Recovery Planning

Current state:

- The app tier can tolerate one app instance failure because the ALB routes to
  healthy targets.
- The database placeholder is not durable or highly available.
- Terraform can recreate infrastructure, but application state is not preserved.

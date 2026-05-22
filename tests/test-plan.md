# Test Plan

## Pre Deployment Tests

1. Format Terraform:

```bash
cd terraform
terraform fmt -check -recursive
```

2. Validate Terraform:

```bash
terraform validate
```

3. Review plan:

```bash
terraform plan
```

Expected result:

- Terraform shows resources to create.
- No validation errors.
- No unexpected public EC2 instances.

## Deployment Tests

1. Apply Terraform:

```bash
terraform apply
```

2. Get ALB DNS name:

```bash
terraform output alb_dns_name
```

3. Test application root endpoint:

```bash
curl http://$ALB_DNS
```

Expected:

- HTTP 200
- HTML response
- instance ID present
- private IP present
- Availability Zone present
- database status present

4. Test health endpoint:

```bash
curl http://$ALB_DNS/health
```

Expected:

```text
ok
```

5. Test load balancing across app instances:

```bash
export ALB_DNS=app-alb-1196878497.us-east-1.elb.amazonaws.com

for i in {1..20}; do
  curl -s http://$ALB_DNS | awk -F'[<>]' '/class="value">i-/{print $3}'
done | sort | uniq -c
```

Expected:

- Responses should come from more than one app instance.
- A healthy result should show all three app instance IDs over repeated requests.

## AWS Console Checks

- ALB has healthy targets.
- App instances are in private subnets.
- Database placeholder is in a data private subnet.
- App and database instances do not have public IP addresses.
- Data route table has no default route to NAT Gateway or Internet Gateway.

## Cleanup Test

Run:

```bash
terraform destroy
```

Expected:

- Terraform destroys all managed resources.
- No NAT Gateway, ALB, EC2 instances, or unattached EBS volumes remain.

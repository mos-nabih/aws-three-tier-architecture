# Cost Documentation

Region: `us-east-1`

Current infrastructure:

- 1 VPC
- 6 subnets
- 1 Internet Gateway
- 1 NAT Gateway
- 1 Elastic IP for NAT Gateway
- 1 Application Load Balancer
- 3 `t3.micro` app EC2 instances
- 1 `t3.micro` database placeholder EC2 instance
- 4 encrypted gp3 EBS root volumes, 8 GB each

## Itemized Monthly Estimate

| Item | Quantity | Estimate |
|---|---:|---:|
| EC2 `t3.micro` Linux instances | 4 running 24/7 | ~$30.00/month before Free Tier |
| EBS gp3 root volumes | 32 GB total | ~$2.56/month before Free Tier |
| NAT Gateway hourly cost | 1 running 24/7 | ~$32.40/month |
| NAT Gateway processing | Based on usage | `$0.045/GB` in common us-east-1 |
| Application Load Balancer | 1 running 24/7 | ~$16.20/month |
| Data transfer out | Based on usage | Depends on traffic |

Monthly cost:

```text
~$80-$100/month for low traffic
```

Daily cost:

```text
~$2.75-$3.30/day for low traffic
```

## Estimate Calculation

The estimate uses 730 hours as an average month.

```text
EC2:
4 t3.micro instances x $0.0104/hour x 730 hours
= $30.37/month

EBS:
4 instances x 8 GB = 32 GB
32 GB x $0.08/GB-month
= $2.56/month

NAT Gateway:
1 NAT Gateway x $0.045/hour x 730 hours
= $32.85/month

Application Load Balancer:
1 ALB x $0.0225/hour x 730 hours
= $16.43/month

Subtotal before usage-based traffic:
$30.37 + $2.56 + $32.85 + $16.43
= $82.21/month
```

That subtotal is the fixed part of the estimate. These are resources that cost
money just because they are running, even with almost no traffic:

- EC2 instances
- EBS volumes
- NAT Gateway hourly charge
- ALB hourly charge

That is why the estimate starts around `$80/month`.

## Usage Based Costs

The `$80-$100/month` range is a planning estimate. The known fixed subtotal is
about `$82/month`. The upper end leaves a small buffer for usage based charges
such as NAT Gateway processing, ALB LCU usage, and data transfer out.

For this demo, the main cost is not traffic. The main fixed cost is the
NAT Gateway hourly charge.

Daily estimate:

```text
$82.21 / 30 days = $2.74/day

Rounded range:
~$2.75-$3.30/day
```

## Cost Optimization Strategies

Short term optimizations:

- Set `app_instance_count = 1` while developing.
- Destroy the stack immediately after testing.
- Remove NAT Gateway during development if app instances do not need outbound internet.

Medium term optimizations:

- Replace NAT Gateway with a NAT instance for dev environments.
- Use Auto Scaling schedules to run app instances only during demo hours.

Production cost optimizations:

- Use AWS Compute Savings Plans for steady EC2 workloads.
- Pick instance sizes based on CloudWatch metrics.

## ROI Analysis For Optimizations

| Optimization | Savings Potential | Trade-off |
|---|---:|---|
| Reduce app instances from 3 to 1 during development | High for EC2 hours | Does not demonstrate full HA requirement |
| Remove NAT Gateway during development | Very high | Private instances cannot reach internet |
| Replace NAT Gateway with NAT instance | High | More maintenance and lower resilience |
| Destroy after every test | Very high | Requires redeploy time |

The highest return optimization is removing or minimizing NAT Gateway runtime because it has a fixed hourly charge.

## Scaling Cost Projections

Small demo:

- 1 app instance
- 1 database placeholder
- ALB
- NAT Gateway
- Lowest cost, but not fully aligned with the requirement for 3 app instances

Full project demo:

- 3 app instances
- 1 database placeholder
- ALB
- NAT Gateway
- Meets current project requirements

Production style:

- Auto Scaling Group across two AZs
- RDS across multiple Availability Zones
- NAT Gateway per AZ
- CloudWatch logs and alarms
- WAF
- Higher cost, stronger reliability and security

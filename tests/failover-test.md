# Failover Test

Validate that the Application Load Balancer routes traffic only to healthy app
instances.

## Current HA Capabilities

- ALB spans two public subnets across two AZs.
- App instances are distributed across two private subnets.
- Target group health check uses `/health`.

## Test Procedure

After deployment:

1. Confirm all targets are healthy in the ALB target group.
2. Stop one app EC2 instance.
3. Wait for the target group health check to mark it unhealthy.
4. Send repeated requests to the ALB DNS name.
5. Confirm responses continue from remaining healthy instances.
6. Start the stopped instance.
7. Confirm it returns to healthy status.

## Expected Result

- ALB removes the unhealthy target from rotation.
- Application remains reachable through the ALB.
- Stopped instance returns to service after it becomes healthy again.

## Test Results

### Baseline Load Balancing

Command:

```bash
for i in {1..20}; do
  curl -s http://$ALB_DNS | awk -F'[<>]' '/class="value">i-/{print $3}'
done | sort | uniq -c
```

Result:

```text
   7 i-0041fb351f4d31891
   6 i-02f121d4d79e00783
   7 i-03768b6cd9c713ae6
```

Second baseline run:

```text
   6 i-0041fb351f4d31891
   7 i-02f121d4d79e00783
   7 i-03768b6cd9c713ae6
```

The ALB distributed traffic across all three app instances.

### Health Check

Command:

```bash
curl http://$ALB_DNS/health
```

Result:

```text
ok
```

### Private Instance Access Check

Command:

```bash
ssh -i ~/.ssh/bootcamp-kp.pem ec2-user@10.0.21.89
```

Result:

```text
Command was interrupted with Ctrl-C.
```

This supports the expected network behavior: the private data tier instance is
not directly reachable from the local machine.

### Stop One App Instance

Command:

```bash
aws ec2 stop-instances --instance-ids i-0041fb351f4d31891
```

Load balancing result after stopping the instance:

```text
  10 i-02f121d4d79e00783
  10 i-03768b6cd9c713ae6
```

The stopped instance was removed from the traffic rotation, and the ALB
continued serving requests from the two remaining healthy instances.

### Start The App Instance Again

Command:

```bash
aws ec2 start-instances --instance-ids i-0041fb351f4d31891
```

Load balancing result after starting the instance again:

```text
   7 i-0041fb351f4d31891
   7 i-02f121d4d79e00783
   6 i-03768b6cd9c713ae6
```

The restarted instance returned to the ALB rotation after becoming healthy.

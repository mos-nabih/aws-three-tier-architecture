mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }
}

run "default_three_tier_plan" {
  command = plan

  override_resource {
    target          = aws_security_group.alb
    override_during = plan

    values = {
      id = "sg-alb"
    }
  }

  override_resource {
    target          = aws_security_group.app
    override_during = plan

    values = {
      id = "sg-app"
    }
  }

  override_resource {
    target          = aws_lb_target_group.app
    override_during = plan

    values = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/app-target-group/abcdef1234567890"
    }
  }

  assert {
    condition     = aws_vpc.main.cidr_block == var.vpc_cidr
    error_message = "The VPC should use the configured CIDR block."
  }

  assert {
    condition = (
      length(aws_subnet.public) == 2 &&
      length(aws_subnet.app_private) == 2 &&
      length(aws_subnet.data_private) == 2
    )
    error_message = "Each tier should span two subnets."
  }

  assert {
    condition = alltrue([
      for subnet in aws_subnet.public : subnet.map_public_ip_on_launch
    ])
    error_message = "Public subnets should assign public IPs on launch."
  }

  assert {
    condition = alltrue(concat(
      [for subnet in aws_subnet.app_private : subnet.map_public_ip_on_launch == false],
      [for subnet in aws_subnet.data_private : subnet.map_public_ip_on_launch == false]
    ))
    error_message = "Private app and data subnets should not assign public IPs on launch."
  }

  assert {
    condition = alltrue([
      for subnet in concat(aws_subnet.public, aws_subnet.app_private, aws_subnet.data_private) :
      contains(local.availability_zones, subnet.availability_zone)
    ])
    error_message = "All subnets should be placed in the configured availability zones."
  }

  assert {
    condition = (
      aws_security_group.alb.tags.Tier == "presentation" &&
      aws_security_group.app.tags.Tier == "application" &&
      aws_security_group.data.tags.Tier == "data"
    )
    error_message = "Security groups should be tagged with the correct tier."
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.alb_http.cidr_ipv4 == "0.0.0.0/0" &&
      aws_vpc_security_group_ingress_rule.alb_http.from_port == 80 &&
      aws_vpc_security_group_ingress_rule.alb_https.cidr_ipv4 == "0.0.0.0/0" &&
      aws_vpc_security_group_ingress_rule.alb_https.from_port == 443
    )
    error_message = "The ALB should expose HTTP and HTTPS from the internet."
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.app_http_from_alb.referenced_security_group_id == aws_security_group.alb.id &&
      aws_vpc_security_group_ingress_rule.app_https_from_alb.referenced_security_group_id == aws_security_group.alb.id &&
      aws_vpc_security_group_ingress_rule.data_from_app.referenced_security_group_id == aws_security_group.app.id
    )
    error_message = "Application and data ingress should be restricted to the previous tier security group."
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.data_from_app.from_port == var.database_port &&
      aws_vpc_security_group_ingress_rule.data_from_app.to_port == var.database_port &&
      aws_vpc_security_group_egress_rule.app_to_data.from_port == var.database_port &&
      aws_vpc_security_group_egress_rule.app_to_data.to_port == var.database_port
    )
    error_message = "Application-to-data rules should use the configured database port."
  }

  assert {
    condition = (
      length(aws_instance.app) == var.app_instance_count &&
      alltrue([for instance in aws_instance.app : instance.associate_public_ip_address == false]) &&
      aws_instance.database.associate_public_ip_address == false
    )
    error_message = "Application and database instances should be private."
  }

  assert {
    condition = alltrue(concat(
      [for instance in aws_instance.app : instance.metadata_options[0].http_tokens == "required"],
      [aws_instance.database.metadata_options[0].http_tokens == "required"]
    ))
    error_message = "All EC2 instances should require IMDSv2 tokens."
  }

  assert {
    condition = alltrue(concat(
      [for instance in aws_instance.app : instance.root_block_device[0].encrypted],
      [aws_instance.database.root_block_device[0].encrypted]
    ))
    error_message = "All EC2 root block devices should be encrypted."
  }

  assert {
    condition = (
      aws_lb.app.internal == false &&
      aws_lb.app.load_balancer_type == "application" &&
      aws_lb_listener.http.port == 80 &&
      aws_lb_listener.http.default_action[0].target_group_arn == aws_lb_target_group.app.arn
    )
    error_message = "The load balancer should be an internet-facing HTTP ALB forwarding to the app target group."
  }

  assert {
    condition = (
      aws_lb_target_group.app.health_check[0].path == "/health" &&
      aws_lb_target_group.app.health_check[0].matcher == "200" &&
      aws_lb_target_group.app.health_check[0].protocol == "HTTP"
    )
    error_message = "The target group should use the HTTP /health endpoint."
  }

  assert {
    condition = (
      length(aws_lb_target_group_attachment.app) == var.app_instance_count &&
      alltrue([for attachment in aws_lb_target_group_attachment.app : attachment.port == 80])
    )
    error_message = "Every app instance should be registered with the target group on port 80."
  }
}

run "custom_instance_count_and_database_port" {
  command = plan

  variables {
    app_instance_count = 2
    database_port      = 3306
  }

  assert {
    condition     = length(aws_instance.app) == 2
    error_message = "The app instance count variable should control the number of app instances."
  }

  assert {
    condition = (
      length(aws_lb_target_group_attachment.app) == 2 &&
      aws_vpc_security_group_ingress_rule.data_from_app.from_port == 3306 &&
      aws_vpc_security_group_ingress_rule.data_from_app.to_port == 3306 &&
      aws_vpc_security_group_egress_rule.app_to_data.from_port == 3306 &&
      aws_vpc_security_group_egress_rule.app_to_data.to_port == 3306
    )
    error_message = "Database port and target group attachments should follow custom variable values."
  }
}

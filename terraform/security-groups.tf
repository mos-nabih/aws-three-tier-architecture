resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow public HTTP and HTTPS traffic to the load balancer."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "alb-sg"
    Tier = "presentation"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from the internet."
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from the internet."
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app_http" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow ALB to reach application instances on HTTP."
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Allow application traffic only from the load balancer."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "app-sg"
    Tier = "application"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow HTTP from the ALB security group."
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "app_https_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow HTTPS from the ALB security group."
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "app_http_outbound" {
  security_group_id = aws_security_group.app.id
  description       = "Allow outbound HTTP for package installation through NAT."
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "app_https_outbound" {
  security_group_id = aws_security_group.app.id
  description       = "Allow outbound HTTPS for package installation through NAT."
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "app_to_data" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow application instances to reach the data tier."
  referenced_security_group_id = aws_security_group.data.id
  from_port                    = var.database_port
  ip_protocol                  = "tcp"
  to_port                      = var.database_port
}

resource "aws_security_group" "data" {
  name        = "data-sg"
  description = "Allow database traffic only from the application tier."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "data-sg"
    Tier = "data"
  }
}

resource "aws_vpc_security_group_ingress_rule" "data_from_app" {
  security_group_id            = aws_security_group.data.id
  description                  = "Allow database traffic from the app security group."
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.database_port
  ip_protocol                  = "tcp"
  to_port                      = var.database_port
}

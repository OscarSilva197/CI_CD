
/*
resource "aws_alb" "application_load_balancer" {
  name               =  "application-load-balancer" # Naming our load balancer
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  # Referencing the security group
  security_groups = ["${aws_security_group.security_load.id}"]
}

# Security Group para Load_Balancer
resource "aws_security_group" "security_load" {
  name   = "security-load"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    description = "http"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform   = "true"
  }
}

*/
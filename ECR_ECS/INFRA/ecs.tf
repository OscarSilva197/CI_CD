resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
 
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = "${aws_iam_role.ecs_task_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


resource "aws_cloudwatch_log_group" "base_api_client" {
  name = "base-api-client"

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_stream" "base_api_client" {
  name           = "base-api-client"
  log_group_name = aws_cloudwatch_log_group.base_api_client.name
}

##################################################################3

# Create and ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.environment}-ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# ECS Service. 
resource "aws_ecs_service" "dummy_api_service" {
  depends_on = [aws_ecs_task_definition.dummy_api_task]

  name             = "ecs-dummmy-api-service"
  cluster          = aws_ecs_cluster.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.dummy_api_task.id
  desired_count    = 4
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.dummy_api_sg.id]
    subnets = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_service_target_group.arn
    container_name   = "base_api"
    container_port   = 80
  }

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }
  
}


# Now, let's define a tast to run in the just created ECS Cluster
resource "aws_ecs_task_definition" "dummy_api_task" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  # My Dummy API
  # "trashuseraws/dummy:latest", 
  #"516603236472.dkr.ecr.us-east-1.amazonaws.com/ritain-registry:tmf632-party-mgmt-api",
  container_definitions    = <<DEFINITION
  [
    {
      "name"      : "base_api",
      "image"     : "770240298425.dkr.ecr.us-east-1.amazonaws.com/my-repository:tmf632-party-mgmt-api",
      "cpu"       : 512,
      "memory"    : 1024,
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort"      : 80
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "base-api-client",
          "awslogs-stream-prefix": "base-api-client",
          "awslogs-region": "us-east-1"
        }
      },
      "environment": [
        {"name": "APP_ENV", "value": "test"}
      ]
    }
  ]
  DEFINITION
}

###################################################################
###################################################################

# Creat Application Load Balancer for the Dummy API service
resource "aws_alb" "application_load_balancer" {
  name               = "dummy-api-ecs-alb" # Naming our load balancer
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  # Referencing the security group
  security_groups = [aws_security_group.dummy_api_sg.id]

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}


# Register a Target Group, which will be used in the Dummy API service's
# definition
resource "aws_lb_target_group" "api_service_target_group" {
  name        = "dummy-api-service-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    matcher = "200,301,302"
    path = "/organization"
  }

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}


# Create and ALB Listener that points to the Target Group just created
resource "aws_lb_listener" "dummy_api_listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_service_target_group.arn
  }

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}


# Security Group for ECS Dummy API Service
resource "aws_security_group" "dummy_api_sg" {
  name   = "dummy-api-sg"
  vpc_id     = aws_vpc.my_vpc.id

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
    Environment = "${var.environment}"
  }
}

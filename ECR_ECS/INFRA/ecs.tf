
# Cria uma role do IAM para o ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode(
    {
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  }
  )
}
#########################################


# Cria uma política de acesso que permite que a role do ECS execute imagens do ECR
resource "aws_iam_policy" "ecs_execution_policy" {
  name = "ecs-execution-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}
##############################################333

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
##############################################################3

# Anexa a política de acesso à role do ECS
resource "aws_iam_role_policy_attachment" "ecs_execution_policy_attachment" {
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
  role       = aws_iam_role.ecs_execution_role.name
}
resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = "${aws_iam_role.ecs_execution_role.name}"
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
}

resource "aws_cloudwatch_log_group" "base_api_client" {
  name = "base-api-client"
}

resource "aws_cloudwatch_log_stream" "base_api_client" {
  name           = "base-api-client"
  log_group_name = aws_cloudwatch_log_group.base_api_client.name
}

##################################################################3

# Create and ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
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
      "image"     : "${var.docker_image_name}",
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
}


# Register a Target Group, which will be used in the Dummy API service's
# definition
resource "aws_lb_target_group" "api_service_target_group" {
  name        = "dummy-api-service-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id     = aws_vpc.my_vpc.id
  health_check {
    matcher = "200,301,302"
    path = "/organization"
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
}

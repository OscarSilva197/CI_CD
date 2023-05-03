#1--Create ECS cluster

resource "aws_ecs_cluster" "cluster" {
  name = "my-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}


#2 ECS Service. 
resource "aws_ecs_service" "ecs_service" {
  depends_on = [aws_ecs_task_definition.ecs_task]
  name            = "my-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  launch_type     = "FARGATE"
  desired_count   = 4

  network_configuration {
    assign_public_ip = false
    subnets = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups = ["${aws_security_group.security_load.id}"]
  }
lifecycle {
    ignore_changes = [task_definition]
  }

    load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${aws_ecs_task_definition.ecs_task.family}"
    container_port   = 80
  }

  tags = {
    Terraform   = "true"
  }

}

# Criar target_goup

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id     = aws_vpc.my_vpc.id
  health_check {
    matcher = "200,301,302,303"
    path = "/"
  }

  tags = {
    Terraform   = "true"
  }
}


# Cria uma role do IAM para o ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

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

# Cria uma política de acesso que permite que a role do ECS execute imagens do ECR
resource "aws_iam_policy" "ecs_execution_policy" {
  name = "ecs_execution_policy"
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

# Anexa a política de acesso à role do ECS
resource "aws_iam_role_policy_attachment" "ecs_execution_policy_attachment" {
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
  role       = aws_iam_role.ecs_execution_role.name
}

# Adiciona a role do ECS à sua definição de tarefa do ECS
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "my-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn # Adiciona a role do ECS como a role de execução
  container_definitions    = <<DEFINITION
  [
    {
      "name"                 : "my-service",
      "image"                : "770240298425.dkr.ecr.us-east-1.amazonaws.com/my-repository:tmf632-party-mgmt-api",
      "cpu"                  : 512,
      "memory"               : 2048,
      "essential"            : true,
      "portMappings" : [
        {
          "containerPort"    : 80,
          "hostPort"         : 80
        }
      ]
    }
  ]
  DEFINITION
}

# Create and ALB Listener that points to the Target Group just created
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  tags = {
    Terraform   = "true"
  }
}
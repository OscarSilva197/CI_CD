# Define as credenciais de acesso da AWS
provider "aws" {
  region = "us-east-1"
}

# Cria um repositório ECR
resource "aws_ecr_repository" "my_repository" {
  name = "my-repository"
}

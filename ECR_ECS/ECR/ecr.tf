
# Define as credenciais de acesso da AWS
provider "aws" {
  region = "us-east-1"
}

# Cria um repositório ECR
resource "aws_ecr_repository" "my_repository" {
  name = "my-repository"
}

#           Outputs            #

output "aws_ecr_registry_id" {
  value = aws_ecr_repository.my_repository.registry_id
}

output "aws_ecr_repository_url" {
  value = aws_ecr_repository.my_repository.repository_url
}
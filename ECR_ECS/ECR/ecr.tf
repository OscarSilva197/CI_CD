
# Define as credenciais de acesso da AWS
provider "aws" {
  region = "us-east-1"
}

# Cria um repositório ECR
resource "aws_ecr_repository" "my_repository" {
  name = "my-repository"
  image_tag_mutability            = "IMMUTABLE"             # Added after checkov analysis
  image_scanning_configuration {                            # Added after checkov analysis
    scan_on_push = true
  } 
  encryption_configuration {                                # Added after checkov analysis
    encryption_type                 = "KMS"                   
  }
  force_delete                    = true
}

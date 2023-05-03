
/*
provider "aws" {
  region = "us-east-1"
}
*/
# Configure the Docker & AWS Providers

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.20.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.20"
    }
  }
}

provider "docker" {}

provider "aws" {
  region     = "us-east-1"
}


/*
terraform {
  backend "s3" {}
}
*/
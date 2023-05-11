/*
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
*/

terraform {
  required_version = ">= 1.0.7"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.20.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 1.0.0"
    }
  }
  }

  /*

  backend "s3" {
    bucket = "silvaoscarda"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }

provider "aws" {
  access_key = "AKIA3GVPGHW4VN46WPWN"
  secret_key = "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"
  region     = "us-east-1"
}*/

provider "docker" {}




variable "region" {
  description = "AWS resources Region"
  type        = string
  default     = "us-east-1"
}

variable "region_a" {
  description = "Region One "
  type        = string
  default     = "us-east-1a"
}
variable "region_b" {
  description = "Region two"
  type        = string
  default     = "us-east-1b"
}

variable "cidr" {
  description = "CIDR range for created VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_cidr_a" {
  description = "CIDR range for created VPC"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_cidr_b" {
  description = "CIDR range for created VPC"
  type        = string
  default     = "10.0.2.0/24"
}
/*
variable "environment" {
  description = "Deployment Environment"
}
*/
variable "docker_image_name" {}

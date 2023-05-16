
module "INFRA" {
  source                  = "./ECR_ECS/INFRA"
  depends_on              = [module.INFRA]
  docker_image_name       = var.docker_image_name
  environment             = var.environment
}

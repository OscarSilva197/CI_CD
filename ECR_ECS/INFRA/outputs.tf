#name of cluster.
output "aws_ecs_cluster" {
  value       = aws_ecs_cluster.cluster.name
  description = "name of cluster"
}

#Compute serverless engine for ECS.
output "aws_ecs_cluster_capacity_providers" {
  value       = aws_ecs_cluster_capacity_providers.cluster.capacity_providers
  description = "Compute serverless engine for ECS"
}
/*
output "alb_address" {
  value = aws_alb.application_load_balancer.dns_name
}
*/

output "alb_address" {
  value = "http://${module.INFRA.aws_alb.application_load_balancer.dns_name}"
}
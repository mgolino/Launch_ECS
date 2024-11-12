

output "AWS_AZs" {
    value = data.aws_availability_zones.available.names
}

output "AWS_VPC" {
    value = aws_vpc.ecs_vpc.id
}
  
output "AWS_SG" {
  value = aws_security_group.ecs_tasks_SG.id
}

output "Cluster_Name" {
  value = aws_ecs_cluster.main.id
}

# output "EBS_Key" {
#   value = aws_ebs_default_kms_key.id
# }
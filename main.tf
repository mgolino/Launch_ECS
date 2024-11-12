# Define the AWS provider

data "aws_availability_zones" "available" {}
#data "aws_ebs_default_kms_key" "ebs_kms_key" {}

# Create a VPC
resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ecs-fargate-vpc"
  }
}

# Create public subnets
resource "aws_subnet" "private" {
  count             = 2  # Number of subnets
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ecs_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "ecs-fargate-private-subnet-${count.index + 1}"
  }
}

# Create an ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "MPG-fargate-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Define the task definition for your ECS Fargate task
resource "aws_ecs_task_definition" "MPG_fargate_app" {
  family                   = "MPG_fargate_app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  
  container_definitions = jsonencode([
    {
      name: "MPG-task-1",
      image: "MPG-task-1",
      cpu: 10,
      memory: 512,
      essential: true,
      portMappings: [
        {
          containerPort: 443,
          hostPort: 443
        }
      ]
     }
     ,
    {
      name: "MPG-task-2",
      image: "MPG-task-2",
      cpu: 10,
      memory: 512,
      essential: true,
      portMappings: [
        {
          containerPort: 80,
          hostPort: 80
        }
      ]
    }  
  ])
#   volume {
#     name      = "service-storage"
#     host_path = "/ecs/service-storage"
#   }

#   placement_constraints {
#     type       = "memberOf"
#     expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
#   }
 }

# Security Group for ECS tasks
resource "aws_security_group" "ecs_tasks_SG" {
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "MPG_ECS_SG"
  }
}

# ECS Service to run the task
resource "aws_ecs_service" "main" {
  name            = "ecs-fargate-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.MPG_fargate_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  #iam_role        = aws_iam_role.foo.arn
  #depends_on      = [aws_iam_role_policy.foo]

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_tasks_SG.id]
    assign_public_ip = false
  }
}
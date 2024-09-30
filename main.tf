### provides ###
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.4"
}
provider "null" {}
provider "template" {}
provider "random" {}
provider "aws" {
  region = var.aws_region
}
### VPC ###
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

#### NAT Gateway ####
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public[0].id
}

resource "aws_eip" "main" {
  domain = "vpc"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public.*.id)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private.*.id)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "allow_http" {
  name        = "allow-http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8002
    to_port     = 8002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Default egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "send_any_email" {
  name = "send-any-email"
  force_delete = true
}

resource "null_resource" "build_and_push_send_any_email" {
  provisioner "local-exec" {
    command = <<EOT
      ./build_push.sh send-any-email ${aws_ecr_repository.send_any_email.repository_url} ${var.docker_image_tag} ${var.aws_region}
    EOT
  }
  depends_on = [aws_ecr_repository.send_any_email]
}

resource "aws_lb" "send_any_email" {
  name               = "send-any-email-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_lb_target_group" "send_any_email" {
  name        = "send-any-email-target-group"
  port        = 8002
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/api"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "send_any_email" {
  load_balancer_arn = aws_lb.send_any_email.arn
  port              = 8002
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.send_any_email.arn
  }
}
resource "aws_lb_listener" "send_any_email_http" {
  load_balancer_arn = aws_lb.send_any_email.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.send_any_email.arn
  }
}

resource "random_password" "redis_pass" {
  length           = 16
  special          = false
}

### SES ###


resource "aws_ses_email_identity" "email_identity" {
  email    = var.email_addresses
}

resource "aws_iam_user" "ses_smtp_user" {
  name = var.iam_user_name
}

resource "aws_iam_user_policy_attachment" "ses_send_policy_attachment" {
  user       = aws_iam_user.ses_smtp_user.name
  policy_arn = var.policy_ses_arn
}

resource "aws_iam_access_key" "ses_smtp_credentials" {
  user = aws_iam_user.ses_smtp_user.name
}

### ECS ###

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# ### remove this after debugging start ###
# resource "aws_iam_role_policy_attachment" "ecs_exec_ssm" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_role_policy_attachment" "ecs_service_role" {
#   role       = aws_iam_role.ecs_task_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }
# ### remove this after debugging end ###

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "main" {
  name = "main-cluster"
}

resource "aws_cloudwatch_log_group" "send_any_email_log_group" {
  name = "/aws/send_any_mail"
}

data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "send_any_email" {
  family                   = "send-any-email-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  # task_role_arn            = aws_iam_role.ecs_task_execution_role.arn  # Remove this after debugging

  container_definitions = jsonencode([
    {
      name      = "send-any-email"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/send-any-email:${var.docker_image_tag}"
      essential = true
      # init_process_enabled = true  # Remove this after debugging
      portMappings = [{
        containerPort = 8002
        hostPort      = 8002
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.send_any_email_log_group.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs_send-any-email"
        }
      } 
      environment = [
        {
          name  = "REDIS_HOST"
          value = var.redis_host
        },
        {
          name  = "REDIS_PORT"
          value = var.redis_port
        },
        {
          name  = "REDIS_USER"
          value = var.redis_user
        },
        {
          name  = "REDIS_PASS"
          value = random_password.redis_pass.result
        },
        {
          name  = "EMAIL_HOST"
          value = "email-smtp.${var.aws_region}.amazonaws.com"
        },
        {
          name  = "EMAIL_PORT"
          value = var.email_port
        },
        {
          name  = "EMAIL_USER"
          value = aws_iam_access_key.ses_smtp_credentials.id
        },
        {
          name  = "EMAIL_PASS"
          value = aws_iam_access_key.ses_smtp_credentials.ses_smtp_password_v4
        },
        {
          name  = "EMAIL_FROM"
          value = var.email_addresses
        }
      ]
      command = ["npm", "run", "start:prod"]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8002/api || exit 1"]
        interval    = 10
        timeout     = 5
        startPeriod = 30
        retries     = 3
      }
    },
    {
      name      = "redis"
      image     = "redis:latest"
      essential = true
      command = ["redis-server", "--requirepass", random_password.redis_pass.result]
      healthCheck = {
        command     = ["CMD-SHELL", "redis-cli ping"]
        interval    = 10
        timeout     = 5
        startPeriod = 10
        retries     = 3
      }
      portMappings = [{
        containerPort = 6379
        hostPort      = 6379
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.send_any_email_log_group.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs_redis"
        }
      }      
    }
  ])
}

resource "aws_ecs_service" "send_any_email" {
  name            = "send-any-email-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.send_any_email.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  # enable_execute_command = true # Remove this after debugging
  network_configuration {
    subnets = [for subnet in aws_subnet.private : subnet.id]
    security_groups = [aws_security_group.allow_http.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.send_any_email.arn
    container_name   = "send-any-email"
    container_port   = 8002
  }
  depends_on = [aws_lb_listener.send_any_email]
}

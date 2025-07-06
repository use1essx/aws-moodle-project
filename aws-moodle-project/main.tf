# =====================
# VPC Module
# =====================
module "vpc" {
  source = "./modules/vpc"
}

# =====================
# Security Groups
# =====================
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "moodle_ec2" {
  name        = "moodle-ec2-sg"
  description = "Security group for Moodle EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Allow HTTP from ALB
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Allow HTTPS from ALB
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH (optional, restrict as needed)
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.moodle_ec2.id] # Only allow from Moodle EC2
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =====================
# RDS Module
# =====================
module "rds" {
  source                = "./modules/rds"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnets
  rds_security_group_id = aws_security_group.rds.id
  rds_instance_count    = 1
}

# =====================
# Application Load Balancer
# =====================
resource "aws_lb" "moodle" {
  name               = "moodle-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Environment = "moodle"
    Project     = "ITP4122"
  }
}

resource "aws_lb_target_group" "moodle" {
  name     = "moodle-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "moodle" {
  load_balancer_arn = aws_lb.moodle.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.moodle.arn
  }
}

# =====================
# EC2 Instance for Moodle
# =====================
resource "aws_launch_template" "moodle" {
  name_prefix   = "moodle-ec2-"
  image_id      = "ami-08c40ec9ead489470" # Ubuntu 22.04 LTS in us-east-1
  instance_type = "t3.micro"
  key_name      = "vockey"
  vpc_security_group_ids = [aws_security_group.moodle_ec2.id]
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
    docker rm -f moodle || true
    docker pull bitnami/moodle:latest
    docker run -d --name moodle \
      -p 8080:8080 -p 8443:8443 \
      -e MOODLE_DATABASE_HOST=${module.rds.db_endpoint} \
      -e MOODLE_DATABASE_PORT_NUMBER=3306 \
      -e MOODLE_DATABASE_USER=admin \
      -e MOODLE_DATABASE_NAME=moodledb \
      -e MOODLE_DATABASE_PASSWORD=${module.rds.db_password} \
      bitnami/moodle:latest
  EOF
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "moodle-ec2"
    }
  }
}

resource "aws_autoscaling_group" "moodle" {
  name                      = "moodle-asg"
  min_size                  = 2
  max_size                  = 2
  desired_capacity          = 2
  vpc_zone_identifier       = module.vpc.public_subnets
  target_group_arns         = [aws_lb_target_group.moodle.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  launch_template {
    id      = aws_launch_template.moodle.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "moodle-ec2"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

output "moodle_url" {
  value = aws_lb.moodle.dns_name
  description = "Moodle application URL"
} 
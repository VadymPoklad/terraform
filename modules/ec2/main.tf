# ------------------------------------------------------------------------------
# IAM РОЛЬ ДЛЯ EC2 (Доступ до Secrets Manager)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "app_role" {
  name = "${var.environment}-asg-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "secrets_policy" {
  name        = "${var.environment}-asg-secrets-policy"
  description = "Allow EC2 to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.environment}-asg-app-profile"
  role = aws_iam_role.app_role.name
}

# ------------------------------------------------------------------------------
# ГРУПИ БЕЗПЕКИ
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Security Group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name        = "${var.environment}-asg-app-sg"
  description = "Security Group for EC2 Instances inside ASG"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB on port 3000 (Next.js)"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------------
# БАЛАНСУВАЛЬНИК НАВАНТАЖЕННЯ (ALB) ТА ЦІЛЬОВА ГРУПА (TARGET GROUP)
# ------------------------------------------------------------------------------
resource "aws_lb" "app_alb" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.environment}-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ------------------------------------------------------------------------------
# ШАБЛОН ЗАПУСКУ ТА ГРУПА АВТОМАСШТАБУВАННЯ (ASG)
# ------------------------------------------------------------------------------
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = var.ami_id
  instance_type = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Скрипт автоматично запуститься при старті
  user_data = base64encode(<<-EOF
    #!/bin/bash
    
    # Создаем файл подкачки (Swap) на 2GB, чтобы избежать ошибки "Killed" (нехватка памяти) при билде Next.js
    dd if=/dev/zero of=/swapfile bs=128M count=16
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    sudo -u ec2-user -i /home/ec2-user/jira-clone/start.sh
  EOF
  )
}

resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.environment}-asg"
  vpc_zone_identifier = var.private_subnet_ids 
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  # 1 інстанс на кожну з 2 підмереж = 2 бажаних. Максимум 2.
  desired_capacity = 2
  max_size         = 2
  min_size         = 2

  health_check_type         = "ELB"
  health_check_grace_period = 900

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-app-server"
    propagate_at_launch = true
  }
}
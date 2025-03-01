provider "aws" {
  region = "ap-south-1"
}

# VPCs
resource "aws_vpc" "Home_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "Home_vpc" }
}

resource "aws_vpc" "Cart_vpc" {
  cidr_block = "10.1.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "Cart_vpc" }
}

# Subnets (Private)
resource "aws_subnet" "Home_subnet" {
  vpc_id     = aws_vpc.Home_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = { Name = "Home_subnet" }
}

resource "aws_subnet" "Cart_subnet" {
  vpc_id     = aws_vpc.Cart_vpc.id
  cidr_block = "10.1.1.0/24"
  tags = { Name = "Cart_subnet" }
}

# Internet Gateway (For Outbound Access)
resource "aws_internet_gateway" "Home_igw" {
  vpc_id = aws_vpc.Home_vpc.id
  tags = { Name = "Home_IGW" }
}

resource "aws_internet_gateway" "Cart_igw" {
  vpc_id = aws_vpc.Cart_vpc.id
  tags = { Name = "Cart_IGW" }
}

# Route Table for Internet Access
resource "aws_route_table" "Home_route" {
  vpc_id = aws_vpc.Home_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Home_igw.id
  }
  tags = { Name = "Home_Route" }
}

resource "aws_route_table" "Cart_route" {
  vpc_id = aws_vpc.Cart_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Cart_igw.id
  }
  tags = { Name = "Cart_Route" }
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.Home_vpc.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template for Auto Scaling
resource "aws_launch_template" "Home_template" {
  name_prefix   = "home-template"
  image_id      = "ami-12345678" # Replace with your AMI
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}

resource "aws_launch_template" "Cart_template" {
  name_prefix   = "cart-template"
  image_id      = "ami-12345678" # Replace with your AMI
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}

# Auto Scaling Groups
resource "aws_autoscaling_group" "Home_asg" {
  vpc_zone_identifier = [aws_subnet.Home_subnet.id]
  desired_capacity   = 1
  min_size          = 1
  max_size          = 2
  launch_template {
    id      = aws_launch_template.Home_template.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_group" "Cart_asg" {
  vpc_zone_identifier = [aws_subnet.Cart_subnet.id]
  desired_capacity   = 1
  min_size          = 1
  max_size          = 2
  launch_template {
    id      = aws_launch_template.Cart_template.id
    version = "$Latest"
  }
}

# Load Balancer
resource "aws_lb" "App_ALB" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id]
  subnets           = [aws_subnet.Home_subnet.id, aws_subnet.Cart_subnet.id]
}

# Load Balancer Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.App_ALB.arn
  port             = "80"
  protocol         = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.App_TG.arn
  }
}

# Target Group
resource "aws_lb_target_group" "App_TG" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Home_vpc.id
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "Home_attach" {
  target_group_arn = aws_lb_target_group.App_TG.arn
  target_id        = aws_autoscaling_group.Home_asg.id
}

resource "aws_lb_target_group_attachment" "Cart_attach" {
  target_group_arn = aws_lb_target_group.App_TG.arn
  target_id        = aws_autoscaling_group.Cart_asg.id
}

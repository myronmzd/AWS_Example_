provider "aws" {
  region = "ap-south-1"
}

provider "aws" {
  alias  = "ap_south_2"
  region = "ap-south-2"
}

variable "my_ip" {
  default = "45.127.45.86/32"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_ap_south_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "subnet_ap_south_2" {
  provider         = aws.ap_south_2
  vpc_id           = aws_vpc.main.id
  cidr_block       = "10.0.2.0/24"
  availability_zone = "ap-south-2a"
}

resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "lt_ap_south_1" {
  name_prefix   = "lt-ap-south-1"
  image_id      = "ami-0abcdef1234567890"
  instance_type = "t2.micro"
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance_sg.id]
  }
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              cat <<EOT > /usr/share/nginx/html/index.html
              <!DOCTYPE html>
              <html>
              <head><title>My Custom Page</title></head>
              <body><h1>Welcome to My Custom Website - AP-SOUTH-1</h1></body>
              </html>
              EOT
              systemctl start nginx
              systemctl enable nginx
              EOF
  )
}

resource "aws_autoscaling_group" "asg_ap_south_1" {
  vpc_zone_identifier = [aws_subnet.subnet_ap_south_1.id]
  desired_capacity   = 1
  max_size          = 2
  min_size          = 1
  launch_template {
    id      = aws_launch_template.lt_ap_south_1.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "lt_ap_south_2" {
  provider      = aws.ap_south_2
  name_prefix   = "lt-ap-south-2"
  image_id      = "ami-0abcdef1234567890"
  instance_type = "t2.micro"
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance_sg.id]
  }
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              cat <<EOT > /usr/share/nginx/html/index.html
              <!DOCTYPE html>
              <html>
              <head><title>My Custom Page</title></head>
              <body><h1>Welcome to My Custom Website - AP-SOUTH-2</h1></body>
              </html>
              EOT
              systemctl start nginx
              systemctl enable nginx
              EOF
  )
}

resource "aws_autoscaling_group" "asg_ap_south_2" {
  provider            = aws.ap_south_2
  vpc_zone_identifier = [aws_subnet.subnet_ap_south_2.id]
  desired_capacity   = 1
  max_size          = 2
  min_size          = 1
  launch_template {
    id      = aws_launch_template.lt_ap_south_2.id
    version = "$Latest"
  }
}

resource "aws_lb" "alb" {
  name               = "multi-region-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.instance_sg.id]
  subnets           = [aws_subnet.subnet_ap_south_1.id, aws_subnet.subnet_ap_south_2.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port             = "80"
  protocol         = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}

resource "aws_lb_target_group" "target" {
  name     = "multi-region-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "attach_ap_south_1" {
  target_group_arn = aws_lb_target_group.target.arn
  target_id        = aws_autoscaling_group.asg_ap_south_1.id
}

resource "aws_lb_target_group_attachment" "attach_ap_south_2" {
  provider         = aws.ap_south_2
  target_group_arn = aws_lb_target_group.target.arn
  target_id        = aws_autoscaling_group.asg_ap_south_2.id
}

locals {
    instance_ami = "ami-0022f774911c1d690"
    subnet_ids   = data.aws_ssm_parameters_by_path.vpc_subnets.values
}

resource "aws_launch_template" "website_lt" {
  name = "website_launch_template"

  image_id = local.instance_ami

  instance_type = "t2.micro"

  key_name = "upbKeyPair"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.upb_instance_sg.id]
  }

#   vpc_security_group_ids = 

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "asg-instance"
    }
  }

  user_data = filebase64("${path.module}/user_data.sh")
}

resource "aws_autoscaling_group" "website_asg" {
  vpc_zone_identifier = local.subnet_ids
  desired_capacity   = 2
  max_size           = 3
  min_size           = 1
  
  # target_group_arns  = [
  #   aws_lb_target_group.website_tg.arn
  # ]

  launch_template {
    id      = aws_launch_template.website_lt.id
    version = "$Latest"
  }
}

resource "aws_lb_target_group" "website_tg" {
  name        = "website-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id_parameter.value
}

resource "aws_security_group" "upb_load_balancer_sg" {
  name        = "upb-load-balancer-sg"
  vpc_id      = data.aws_ssm_parameter.vpc_id_parameter.value

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  tags = {
    Name = "upb-load-balancer-sg"
  }
}

resource "aws_security_group" "upb_instance_sg" {
  name        = "upb-instance-sg"
  vpc_id      = data.aws_ssm_parameter.vpc_id_parameter.value

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  # ingress {
  #   description      = "http traffic"
  #   from_port        = 80
  #   to_port          = 80
  #   protocol         = "tcp"
  #   cidr_blocks      = ["0.0.0.0/0"]
  # }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "upb-instance-sg"
  }
}

resource "aws_lb" "upb_alb" {
  name               = "upb-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.upb_load_balancer_sg.id]
  subnets            = local.subnet_ids

}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.website_asg.id
  lb_target_group_arn    = aws_lb_target_group.website_tg.arn
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.upb_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.website_tg.arn
  }
}

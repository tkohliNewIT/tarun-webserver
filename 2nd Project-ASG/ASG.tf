provider "aws" {
  region = "us-east-1"
}

resource "aws_launch_configuration" "MyLaunchConfig" {
    image_id ="ami-0022f774911c1d690"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
  
lifecycle {
  create_before_destroy = true
}

}

resource "aws_autoscaling_group" "MyAsg" {
    launch_configuration = aws_launch_configuration.MyLaunchConfig.name
    min_size = 0
    max_size = 10
    vpc_zone_identifier = data.aws_subnet_ids.default.ids
    target_group_arns = [aws_lb_target_group.ATG.arn]
    health_check_type = "ELB"

    tag {
      key = "Name"
      value = "Terraform-asg-example"
      propagate_at_launch = true
    }
  


}

data "aws_vpc" "default" {
    default = true

}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
  
}

resource "aws_security_group" "instance" {
    name = "Prod-instance"

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "Webserver-traffic"
      from_port = var.server_port
      protocol = "tcp"
      to_port = var.server_port
    } 
    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "Ping"
      from_port = 1
      protocol = "icmp"
      to_port = 1
    } 
    
    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "Ping"
      from_port = 22
      protocol = "tcp"
      to_port = 22
    } 

    egress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "Webserver-traffic"
      from_port = var.server_port
      protocol = "tcp"
      to_port = var.server_port
    }
    egress {
     cidr_blocks = [ "0.0.0.0/0" ]
      description = "Ping"
      from_port = 1
      protocol = "icmp"
      to_port = 1
    } 

}

resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
  
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404:page not found"
      status_code = 404
      
    
  }
 
}
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "ALB http traffic"
    from_port = 80
    protocol = "tcp"
    to_port = 80
  } 

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "ALB Http traffic"
    from_port = 0
    protocol = "-1"
    to_port = 0
  } 
  
}

resource "aws_lb_target_group" "ATG" {
  name = "terraform-atg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

 health_check {
   path = "/"
   protocol = "HTTP"
   matcher = "200"
   interval = 15
   timeout = 3
   healthy_threshold = 2
   unhealthy_threshold = 4
       
 }

}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
    
  }
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.ATG.arn
    
  }
  
}

resource "aws_subnet" "main" {
  vpc_id     = data.aws_vpc.default.id
  cidr_block = "172.31.0.0/19"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Main"
  }
}
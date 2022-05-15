provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "Prod1_EC2" {
    ami = "ami-0022f774911c1d690"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

    tags = {
      "Name" = "Prod-App1"
    }
  }

/*resource "aws_instance" "Prod2_EC2" {
    ami = "ami-0022f774911c1d690"
    instance_type = "t2.micro"

tags = {
  "Name" = "Prod-App2"
}

}*/

resource "aws_security_group" "instance" {
    name = "Prod-App1-instance"

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
  
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type = number
    default = 8080
  
}

output "public_ip" {
    description = "The Public IP Address of the Webserver"
    value = aws_instance.Prod1_EC2.public_ip
  
}
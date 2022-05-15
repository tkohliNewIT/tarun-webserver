provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "Prod1_EC2" {
    ami = "ami-0022f774911c1d690"
    instance_type = "t2.micro"

    tags = {
      "name" = "Prod-App1"
    }
  }

resource "aws_instance" "Prod2_EC2" {
    ami = "ami-0022f774911c1d690"
    instance_type = "t2.micro"

}

  
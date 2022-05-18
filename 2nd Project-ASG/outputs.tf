output "alb_dns_name" {
    description = "the domain name of the load balancer"
    value = aws_lb.example.dns_name
}

output "vpc_id" {
    value = data.aws_vpc.default.id
  
}

output "Subnet_ids" {
    value = data.aws_subnet_ids.default.ids
  
}
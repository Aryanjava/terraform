# Notes for future purpose
# Outputs are how Terraform hands you back useful
# values after `apply` finishes — you don't have to go hunting in
# the AWS console. They're also how you pass data between separate
# Terraform projects/modules in bigger setups.



output "alb_dns_name" {
  description = "Public URL to hit your load-balanced app — open this in a browser"
  value       = aws_lb.main.dns_name
}

output "ec2_instance_ids" {
  description = "The 2 EC2 instance IDs behind the load balancer"
  value       = aws_instance.web[*].id
}

output "ec2_public_ips" {
  description = "Public IPs of each EC2 instance (useful for direct SSH debugging)"
  value       = aws_instance.web[*].public_ip
}

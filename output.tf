### outputs ###

output "send_any_email_repository_url" {
  value = aws_ecr_repository.send_any_email.repository_url
}

output "nat_gateway_public_ip" {
  value = aws_eip.main.public_ip
  description = "The public IP address of the NAT Gateway."
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.send_any_email.dns_name
}

output "ecs_service_load_balancer_port" {
  description = "The port on which the ECS service is listening on the load balancer"
  value       = aws_lb_listener.send_any_email.port
  
}

# Output SMTP username
output "smtp_username" {
  value = aws_iam_access_key.ses_smtp_credentials.id
}
# Output SMTP password - can be get from state file
output "smtp_password" {
  value = aws_iam_access_key.ses_smtp_credentials.ses_smtp_password_v4
  sensitive = true
}
output "public_ip" {
  value       = aws_instance.jenkins_server.public_ip
}

output "dns" {
  value       = aws_lb.web_alb.dns_name
}

output "ec2_public_dns" {
  value = aws_instance.jenkins_server.public_dns
  
}

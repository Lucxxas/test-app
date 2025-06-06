# Outputs pour Ansible
output "instance_ips" {
  description = "Public IPs of all instances for Ansible"
  value       = aws_instance.TP-FINAL-WEB.public_ip
}

output "web_instance_ip" {
  description = "Public IP of WEB instance"
  value       = aws_instance.TP-FINAL-WEB.public_ip
}

output "app_instance_ip" {
  description = "Public IP of APP instance"
  value       = aws_instance.TP-FINAL-APP.public_ip
}

output "db_instance_ip" {
  description = "Public IP of DB instance"
  value       = aws_instance.TP-FINAL-BDD.public_ip
}

output "private_key_ssm_name" {
  description = "SSM Parameter name for SSH private key"
  value       = aws_ssm_parameter.private_key.name
}

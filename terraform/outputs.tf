# terraform/outputs.tf
output "instance_ips" {
  value = aws_instance.your_instance_name.public_ip
}

output "key_ssm_param" {
  value = aws_ssm_parameter.private_key.name
}

output "public_ip" {
  value = aws_instance.TP-FINAL-WEB.public_ip
}

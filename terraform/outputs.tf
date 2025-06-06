# terraform/outputs.tf
output "instance_ips" {
  value = aws_instance.your_instance_name.public_ip
}

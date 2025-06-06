
output "web_instance_ip" {
  description = "Public IP of the web instance"
  value       = aws_instance.TP-FINAL-WEB.public_ip
}

output "app_instance_ip" {
  description = "Public IP of the app instance"
  value       = aws_instance.TP-FINAL-APP.public_ip
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.TP-FINAL-DB.endpoint
}

output "ssh_private_key" {
  description = "SSH private key"
  value       = tls_private_key.TP-FINAL_key.private_key_pem
  sensitive   = true
}

# Outputs pour le stack Ansible
output "ansible_inventory" {
  description = "Ansible inventory in JSON format"
  value = jsonencode({
    web = {
      hosts = {
        web_server = {
          ansible_host = aws_instance.TP-FINAL-WEB.public_ip
          ansible_user = "ec2-user"
        }
      }
    }
    app = {
      hosts = {
        app_server = {
          ansible_host = aws_instance.TP-FINAL-APP.public_ip
          ansible_user = "ec2-user"
        }
      }
    }
    all = {
      vars = {
        database_endpoint = aws_db_instance.TP-FINAL-DB.endpoint
        database_name = "webappdb"
        database_user = "admin"
        database_password = var.db_password
      }
    }
  })
}

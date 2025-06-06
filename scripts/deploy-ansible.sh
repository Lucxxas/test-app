#!/bin/bash

# 🚀 Déployement automatique avec Ansible
# Usage: ./deploy-ansible.sh

set -e

echo "🚀 Deploying 3-tier architecture with Ansible..."

# Vérifier que le fichier d'IPs existe
if [ ! -f "../ansible/terraform_ips.json" ]; then
    echo "❌ IP file not found: ../ansible/terraform_ips.json"
    echo "🔍 Trying to create it manually..."
    
    # Essayer de récupérer les IPs depuis les outputs Terraform
    WEB_IP=$(terraform output -raw web_instance_ip 2>/dev/null || echo "")
    APP_IP=$(terraform output -raw app_instance_ip 2>/dev/null || echo "")
    DB_ENDPOINT=$(terraform output -raw database_endpoint 2>/dev/null || echo "")
    
    if [ -z "$WEB_IP" ] || [ -z "$APP_IP" ] || [ -z "$DB_ENDPOINT" ]; then
        echo "❌ Instance IPs not found"
        echo "WEB_IP: '$WEB_IP'"
        echo "APP_IP: '$APP_IP'"
        echo "DB_ENDPOINT: '$DB_ENDPOINT'"
        exit 1
    fi
else
    echo "📋 Reading IPs from: ../ansible/terraform_ips.json"
    
    # Lire les IPs depuis le fichier JSON
    WEB_IP=$(cat ../ansible/terraform_ips.json | jq -r '.web_ip')
    APP_IP=$(cat ../ansible/terraform_ips.json | jq -r '.app_ip')
    DB_ENDPOINT=$(cat ../ansible/terraform_ips.json | jq -r '.db_endpoint')
fi

echo "📋 WEB Instance IP: $WEB_IP"
echo "📋 APP Instance IP: $APP_IP"
echo "📋 Database Endpoint: $DB_ENDPOINT"

echo "🔑 Using SSH key from Terraform..."
# Vérifier que la clé SSH existe
if [ ! -f "../ansible/TP-FINAL-keypair.pem" ]; then
    echo "❌ SSH key not found at ../ansible/TP-FINAL-keypair.pem"
    echo "🔍 Terraform should have created this file..."
    exit 1
fi

chmod 600 ../ansible/TP-FINAL-keypair.pem

echo "📝 Creating Ansible inventory..."
cat > ../ansible/inventory.ini << EOF
[web]
$WEB_IP ansible_user=ubuntu ansible_ssh_private_key_file=./TP-FINAL-keypair.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[app]
$APP_IP ansible_user=ubuntu ansible_ssh_private_key_file=./TP-FINAL-keypair.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[db:vars]
db_endpoint=$DB_ENDPOINT
EOF

echo "✅ Inventory created successfully!"

# Attendre que les instances soient prêtes
echo "⏳ Waiting for instances to be ready..."
sleep 30

# Tester la connectivité
echo "🔍 Testing SSH connectivity..."
cd ../ansible

# Test de connexion avec timeout
for i in {1..5}; do
    echo "   Attempt $i/5..."
    if ansible all -i inventory.ini -m ping --timeout=10; then
        echo "✅ SSH connectivity successful!"
        break
    else
        echo "⚠️  SSH not ready yet, waiting 30s..."
        sleep 30
    fi
    
    if [ $i -eq 5 ]; then
        echo "❌ SSH connectivity failed after 5 attempts"
        echo "🔍 Debug info:"
        ansible all -i inventory.ini -m ping -vvv || true
        exit 1
    fi
done

# Lancer les playbooks Ansible
echo "🎯 Running Ansible playbooks..."

# Playbook pour le serveur Web
if [ -f "web-playbook.yml" ]; then
    echo "📦 Configuring Web server..."
    ansible-playbook -i inventory.ini web-playbook.yml --timeout=300
else
    echo "⚠️  web-playbook.yml not found, skipping..."
fi

# Playbook pour le serveur App
if [ -f "app-playbook.yml" ]; then
    echo "📦 Configuring App server..."
    ansible-playbook -i inventory.ini app-playbook.yml --timeout=300
else
    echo "⚠️  app-playbook.yml not found, skipping..."
fi

# Playbook pour la base de données (configuration si nécessaire)
if [ -f "db-playbook.yml" ]; then
    echo "📦 Configuring Database connections..."
    ansible-playbook -i inventory.ini db-playbook.yml --timeout=300
else
    echo "⚠️  db-playbook.yml not found, skipping..."
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Access Information:"
echo "   🌐 Web Server: http://$WEB_IP"
echo "   ⚙️  App Server: http://$APP_IP:4000"
echo "   🗄️  Database: $DB_ENDPOINT"
echo ""
echo "🔑 SSH Access:"
echo "   ssh -i ./TP-FINAL-keypair.pem ubuntu@$WEB_IP"
echo "   ssh -i ./TP-FINAL-keypair.pem ubuntu@$APP_IP"
echo ""

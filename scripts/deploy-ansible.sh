#!/bin/bash
set -e

echo "🚀 Deploying 3-tier architecture with Ansible..."

# Lire les IPs depuis le fichier créé par Terraform
IP_FILE="../ansible/terraform_ips.json"

if [ ! -f "$IP_FILE" ]; then
    echo "❌ IP file not found: $IP_FILE"
    echo "🔍 Trying to create it manually..."
    
    # Fallback: essayer de créer le dossier et le fichier
    mkdir -p ../ansible
    
    # Utiliser aws cli en fallback
    WEB_IP=$(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=TP-FINAL-WEB-instance" "Name=instance-state-name,Values=running" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text 2>/dev/null || echo "")
    
    APP_IP=$(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=TP-FINAL-APP-instance" "Name=instance-state-name,Values=running" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text 2>/dev/null || echo "")
    
    DB_ENDPOINT=$(aws rds describe-db-instances \
      --db-instance-identifier tp-final-database \
      --query "DBInstances[0].Endpoint.Address" \
      --output text 2>/dev/null || echo "")
else
    echo "📋 Reading IPs from: $IP_FILE"
    WEB_IP=$(cat "$IP_FILE" | jq -r '.web_ip // empty')
    APP_IP=$(cat "$IP_FILE" | jq -r '.app_ip // empty')
    DB_ENDPOINT=$(cat "$IP_FILE" | jq -r '.db_endpoint // empty')
fi

if [ -z "$WEB_IP" ] || [ -z "$APP_IP" ] || [ "$WEB_IP" = "None" ] || [ "$APP_IP" = "None" ]; then
    echo "❌ Instance IPs not found"
    echo "WEB_IP: '$WEB_IP'"
    echo "APP_IP: '$APP_IP'"
    echo "DB_ENDPOINT: '$DB_ENDPOINT'"
    exit 1
fi

echo "📋 WEB Instance IP: $WEB_IP"
echo "📋 APP Instance IP: $APP_IP"
echo "📋 Database Endpoint: $DB_ENDPOINT"

# Récupérer la clé SSH depuis SSM
echo "🔑 Getting SSH key from SSM..."
aws ssm get-parameter --name "/ssh/TP-FINAL-keypair/private" --with-decryption --query 'Parameter.Value' --output text > /tmp/ansible_key
chmod 600 /tmp/ansible_key

# Attendre que les instances soient prêtes
echo "⏳ Waiting for instances..."
sleep 120

# Aller dans le dossier ansible
cd ../ansible/ 2>/dev/null || cd ansible/ || {
    echo "📁 Creating ansible directory..."
    mkdir -p ansible && cd ansible
}

# Créer l'inventaire Ansible
cat > inventory.yml << EOF
[web]
$WEB_IP

[app]
$APP_IP

[db]
$DB_ENDPOINT

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/tmp/ansible_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[db:vars]
ansible_connection=local
database_host=$DB_ENDPOINT
database_name=webappdb
database_user=admin
database_password=Password123!
EOF

echo "📋 Generated inventory:"
cat inventory.yml

# Test de connectivité simplifié
echo "🔍 Testing SSH connectivity..."
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /tmp/ansible_key ubuntu@$WEB_IP "echo 'WEB OK'" 2>/dev/null; then
    echo "✅ WEB instance accessible"
else
    echo "⚠️ WEB instance not ready yet"
fi

if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /tmp/ansible_key ubuntu@$APP_IP "echo 'APP OK'" 2>/dev/null; then
    echo "✅ APP instance accessible"
else
    echo "⚠️ APP instance not ready yet"
fi

# Lancer le playbook Ansible
echo "🎭 Running Ansible playbook..."
ansible-playbook playbook.yml -v

echo "✅ 3-tier deployment completed!"

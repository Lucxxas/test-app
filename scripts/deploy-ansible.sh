#!/bin/bash
set -e

echo "🚀 Deploying 3-tier architecture with Ansible..."

# Récupérer les IPs via AWS CLI (plus fiable que tofu output pendant hooks)
echo "🔍 Getting instance IPs from AWS..."

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

# Créer l'inventaire Ansible pour 3-tier
cd ../ansible/ 2>/dev/null || cd ansible/ || {
    echo "📁 Creating ansible directory..."
    mkdir -p ansible && cd ansible
}

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

# Test de connectivité pour les instances EC2
echo "🔍 Testing connectivity to WEB instance..."
for i in {1..3}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /tmp/ansible_key ubuntu@$WEB_IP "echo 'Connected to WEB'" 2>/dev/null; then
        echo "✅ WEB instance connected"
        break
    else
        echo "⏳ WEB connection attempt $i failed, retrying..."
        sleep 30
    fi
    
    if [ $i -eq 3 ]; then
        echo "⚠️ WEB connection failed after 3 attempts, continuing..."
    fi
done

echo "🔍 Testing connectivity to APP instance..."
for i in {1..3}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /tmp/ansible_key ubuntu@$APP_IP "echo 'Connected to APP'" 2>/dev/null; then
        echo "✅ APP instance connected"
        break
    else
        echo "⏳ APP connection attempt $i failed, retrying..."
        sleep 30
    fi
    
    if [ $i -eq 3 ]; then
        echo "⚠️ APP connection failed after 3 attempts, continuing..."
    fi
done

# Lancer le playbook Ansible
echo "🎭 Running Ansible playbook..."
ansible-playbook playbook.yml -v

echo "✅ 3-tier deployment completed!"

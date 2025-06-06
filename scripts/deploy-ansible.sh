#!/bin/bash
set -e

echo "🚀 Deploying with Ansible..."

# Aller dans le dossier terraform
cd terraform/

# Récupérer l'IP de l'instance WEB (qui sera utilisée pour tous les services)
WEB_IP=$(terraform output -raw instance_ips 2>/dev/null || echo "")

if [ -z "$WEB_IP" ]; then
    echo "❌ No instance IP found"
    exit 1
fi

echo "📋 Instance IP: $WEB_IP"

# Récupérer la clé privée depuis SSM (ou utiliser celle fournie en variable)
if [ -n "$ANSIBLE_PRIVATE_KEY" ]; then
    echo "🔑 Using provided SSH key..."
    echo "$ANSIBLE_PRIVATE_KEY" > /tmp/ansible_key
else
    echo "🔑 Getting SSH key from SSM..."
    aws ssm get-parameter --name "/ssh/TP-FINAL-keypair/private" --with-decryption --query 'Parameter.Value' --output text > /tmp/ansible_key
fi

chmod 600 /tmp/ansible_key

# Attendre que l'instance soit prête
echo "⏳ Waiting for instance..."
sleep 120

# Aller dans le dossier ansible
cd ../ansible/

# Créer l'inventaire dynamique
cat > inventory.yml << EOF
[web]
$WEB_IP

[app]
$WEB_IP

[db]
$WEB_IP

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/tmp/ansible_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=30'
EOF

echo "📋 Generated inventory:"
cat inventory.yml

# Test de connectivité avec retry
echo "🔍 Testing connection..."
for i in {1..5}; do
    if ansible all -m ping; then
        echo "✅ Connection successful"
        break
    else
        echo "⏳ Attempt $i failed, retrying in 30s..."
        sleep 30
    fi
    
    if [ $i -eq 5 ]; then
        echo "❌ Connection failed after 5 attempts"
        exit 1
    fi
done

# Lancer le playbook
echo "🎭 Running playbook..."
ansible-playbook playbook.yml -v

echo "✅ Deployment completed!"

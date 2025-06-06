#!/bin/bash
set -e

echo "🚀 Deploying with Ansible..."

# Récupérer l'IP depuis Terraform
cd terraform/
INSTANCE_IP=$(terraform output -raw instance_ips 2>/dev/null || echo "")

if [ -z "$INSTANCE_IP" ]; then
    echo "❌ No instance IP found"
    exit 1
fi

echo "📋 Instance IP: $INSTANCE_IP"

# Récupérer la clé SSH depuis SSM
echo "🔑 Getting SSH key from SSM..."
aws ssm get-parameter --name "/ssh/TP-FINAL-keypair/private" --with-decryption --query 'Parameter.Value' --output text > /tmp/ansible_key
chmod 600 /tmp/ansible_key

# Attendre que l'instance soit prête
echo "⏳ Waiting for instance..."
sleep 120

# Créer l'inventaire Ansible
cd ../ansible/
cat > inventory.yml << EOF
[web]
$INSTANCE_IP

[app]
$INSTANCE_IP

[db]
$INSTANCE_IP

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/tmp/ansible_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

# Lancer Ansible
ansible-playbook playbook.yml -v

echo "✅ Done!"

#!/bin/bash
set -e

echo "🚀 Deploying with Ansible..."

# Récupérer les IPs depuis Terraform
cd terraform/
INSTANCE_IPS=$(terraform output -raw instance_ips 2>/dev/null || echo "")

if [ -z "$INSTANCE_IPS" ]; then
    echo "❌ No instance IPs found"
    exit 1
fi

echo "📋 Instance IP: $INSTANCE_IPS"

# Préparer SSH key
echo "$ANSIBLE_PRIVATE_KEY" > /tmp/ansible_key
chmod 600 /tmp/ansible_key

# Attendre que l'instance soit prête
echo "⏳ Waiting for instance..."
sleep 90

# Aller dans le dossier ansible
cd ../ansible/

# Créer l'inventaire dynamique (remplacer votre inventory.yml)
cat > inventory.yml << EOF
[web]
$INSTANCE_IPS

[app]
$INSTANCE_IPS

[db]
$INSTANCE_IPS

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/tmp/ansible_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

echo "📋 Generated inventory:"
cat inventory.yml

# Vérifier la connectivité
echo "🔍 Testing connection..."
ansible all -m ping || {
    echo "❌ Connection failed"
    exit 1
}

# Lancer le playbook
echo "🎭 Running playbook..."
ansible-playbook playbook.yml -v

echo "✅ Deployment completed!"
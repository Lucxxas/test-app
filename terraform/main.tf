# Configuration locale pour test
locals {
  aws_region = "us-east-1"
}

# Generate SSH key pair
resource "tls_private_key" "TP-FINAL_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in SSM Parameter Store (optionnel, pour backup)
resource "aws_ssm_parameter" "private_key" {
  name        = "/ssh/TP-FINAL-keypair/private"
  description = "Private SSH key for EC2 TP-FINAL"
  type        = "SecureString"
  value       = tls_private_key.TP-FINAL_key.private_key_pem
  overwrite   = true

  tags = {
    environment = "TP-FINAL"
  }
}

# Create AWS key pair using the public key
resource "aws_key_pair" "TP-FINAL_keypair" {
  key_name   = "TP-FINAL-keypair"
  public_key = tls_private_key.TP-FINAL_key.public_key_openssh
}

# Data source to get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC
resource "aws_vpc" "TP-FINAL_vpc" {
  cidr_block           = "192.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "TP-FINAL-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "TP-FINAL_igw" {
  vpc_id = aws_vpc.TP-FINAL_vpc.id

  tags = {
    Name = "TP-FINAL-igw"
  }
}

# Route Table
resource "aws_route_table" "TP-FINAL_rt" {
  vpc_id = aws_vpc.TP-FINAL_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TP-FINAL_igw.id
  }

  tags = {
    Name = "TP-FINAL-rt"
  }
}

# Subnet WEB (Public)
resource "aws_subnet" "TP-FINAL-WEB_subnet" {
  vpc_id                  = aws_vpc.TP-FINAL_vpc.id
  cidr_block              = "192.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "TP-FINAL-WEB-subnet"
  }
}

# Subnet APP (Public pour simplifier)
resource "aws_subnet" "TP-FINAL-APP_subnet" {
  vpc_id                  = aws_vpc.TP-FINAL_vpc.id
  cidr_block              = "192.0.5.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "TP-FINAL-APP-subnet"
  }
}

# Subnet DB (Private)
resource "aws_subnet" "TP-FINAL-DB_subnet_1" {
  vpc_id            = aws_vpc.TP-FINAL_vpc.id
  cidr_block        = "192.0.6.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "TP-FINAL-DB-subnet-1"
  }
}

# Subnet DB 2 (Private - requis pour RDS)
resource "aws_subnet" "TP-FINAL-DB_subnet_2" {
  vpc_id            = aws_vpc.TP-FINAL_vpc.id
  cidr_block        = "192.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "TP-FINAL-DB-subnet-2"
  }
}

# Route Table Associations
resource "aws_route_table_association" "TP-FINAL_rta_web" {
  subnet_id      = aws_subnet.TP-FINAL-WEB_subnet.id
  route_table_id = aws_route_table.TP-FINAL_rt.id
}

resource "aws_route_table_association" "TP-FINAL_rta_app" {
  subnet_id      = aws_subnet.TP-FINAL-APP_subnet.id
  route_table_id = aws_route_table.TP-FINAL_rt.id
}

# Security Group pour Web Tier
resource "aws_security_group" "TP-FINAL_web_sg" {
  name        = "TP-FINAL-web-sg"
  description = "Security group for web tier"
  vpc_id      = aws_vpc.TP-FINAL_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TP-FINAL-web-sg"
  }
}

# Security Group pour App Tier
resource "aws_security_group" "TP-FINAL_app_sg" {
  name        = "TP-FINAL-app-sg"
  description = "Security group for app tier"
  vpc_id      = aws_vpc.TP-FINAL_vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.TP-FINAL_web_sg.id]
  }

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.TP-FINAL_web_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Pour Ansible
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TP-FINAL-app-sg"
  }
}

# Security Group pour Database
resource "aws_security_group" "TP-FINAL_db_sg" {
  name        = "TP-FINAL-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.TP-FINAL_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.TP-FINAL_app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TP-FINAL-db-sg"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "TP-FINAL_db_subnet_group" {
  name       = "tp-final-db-subnet-group"
  subnet_ids = [aws_subnet.TP-FINAL-DB_subnet_1.id, aws_subnet.TP-FINAL-DB_subnet_2.id]

  tags = {
    Name = "TP-FINAL DB subnet group"
  }
}

# EC2 Instance WEB TIER - Ubuntu 22.04
resource "aws_instance" "TP-FINAL-WEB" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.TP-FINAL-WEB_subnet.id
  key_name               = aws_key_pair.TP-FINAL_keypair.key_name
  vpc_security_group_ids = [aws_security_group.TP-FINAL_web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip git curl wget
    
    # S'assurer que l'utilisateur ubuntu existe et a les bonnes permissions
    usermod -aG sudo ubuntu
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    
    # Préparer SSH
    mkdir -p /home/ubuntu/.ssh
    chown ubuntu:ubuntu /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh
    
    # Installer quelques outils utiles
    apt-get install -y htop unzip
  EOF

  tags = {
    Name = "TP-FINAL-WEB-instance"
  }
}

# EC2 Instance APP TIER - Ubuntu 22.04
resource "aws_instance" "TP-FINAL-APP" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.TP-FINAL-APP_subnet.id
  key_name               = aws_key_pair.TP-FINAL_keypair.key_name
  vpc_security_group_ids = [aws_security_group.TP-FINAL_app_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip git curl wget
    
    # S'assurer que l'utilisateur ubuntu existe et a les bonnes permissions
    usermod -aG sudo ubuntu
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    
    # Préparer SSH
    mkdir -p /home/ubuntu/.ssh
    chown ubuntu:ubuntu /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh
    
    # Installer quelques outils utiles
    apt-get install -y htop unzip
  EOF

  tags = {
    Name = "TP-FINAL-APP-instance"
  }
}

# RDS MySQL Database
resource "aws_db_instance" "TP-FINAL-DB" {
  identifier     = "tp-final-database"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = false

  db_name  = "webappdb"
  username = "admin"
  password = "Password123!"  # À changer en production !

  vpc_security_group_ids = [aws_security_group.TP-FINAL_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.TP-FINAL_db_subnet_group.name

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "TP-FINAL-database"
  }
}

# Outputs pour Ansible
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

output "private_key_ssm_name" {
  description = "SSM Parameter name for SSH private key"
  value       = aws_ssm_parameter.private_key.name
}

output "ssh_private_key" {
  description = "SSH private key for EC2 instances"
  value       = tls_private_key.TP-FINAL_key.private_key_pem
  sensitive   = true
}

output "ubuntu_ami_id" {
  description = "Ubuntu AMI ID used"
  value       = data.aws_ami.ubuntu.id
}

output "ubuntu_ami_name" {
  description = "Ubuntu AMI name"
  value       = data.aws_ami.ubuntu.name
}

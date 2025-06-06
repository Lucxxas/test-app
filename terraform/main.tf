# Generate SSH key pair
resource "tls_private_key" "TP-FINAL_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in SSM Parameter Store
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

# Subnet APP
resource "aws_subnet" "TP-FINAL-APP_subnet" {
  vpc_id                  = aws_vpc.TP-FINAL_vpc.id
  cidr_block              = "192.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "TP-FINAL-APP-subnet"
  }
}

# Subnet WEB
resource "aws_subnet" "TP-FINAL-WEB_subnet" {
  vpc_id                  = aws_vpc.TP-FINAL_vpc.id
  cidr_block              = "192.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "TP-FINAL-WEB-subnet"
  }
}

# Subnet BDD
resource "aws_subnet" "TP-FINAL-BDD_subnet" {
  vpc_id                  = aws_vpc.TP-FINAL_vpc.id
  cidr_block              = "192.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "TP-FINAL-BDD-subnet"
  }
}

# Route Table Association APP
resource "aws_route_table_association" "TP-FINAL_rta" {
  subnet_id      = aws_subnet.TP-FINAL-APP_subnet.id
  route_table_id = aws_route_table.TP-FINAL_rt.id
}

# Route Table Association WEB
resource "aws_route_table_association" "TP-FINAL_rta_2" {
  subnet_id      = aws_subnet.TP-FINAL-WEB_subnet.id
  route_table_id = aws_route_table.TP-FINAL_rt.id
}

# Route Table Association BDD
resource "aws_route_table_association" "TP-FINAL_rta_3" {
  subnet_id      = aws_subnet.TP-FINAL-BDD_subnet.id
  route_table_id = aws_route_table.TP-FINAL_rt.id
}

# Security Group
resource "aws_security_group" "TP-FINAL_sg" {
  name        = "TP-FINAL-sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.TP-FINAL_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port"
    from_port   = 4000
    to_port     = 4000
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
    Name = "TP-FINAL-sg"
  }
}

# EC2 Instance APP
resource "aws_instance" "TP-FINAL-APP" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2023
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.TP-FINAL-APP_subnet.id
  key_name               = aws_key_pair.TP-FINAL_keypair.key_name
  vpc_security_group_ids = [aws_security_group.TP-FINAL_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip
  EOF

  tags = {
    Name = "TP-FINAL-APP-instance"
  }
}

# EC2 Instance WEB (instance principale pour Ansible)
resource "aws_instance" "TP-FINAL-WEB" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2023
  instance_type          = "t2.medium"  # Plus de ressources pour héberger tous les services
  subnet_id              = aws_subnet.TP-FINAL-WEB_subnet.id
  key_name               = aws_key_pair.TP-FINAL_keypair.key_name
  vpc_security_group_ids = [aws_security_group.TP-FINAL_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip git
    # Créer un utilisateur pour Ansible
    useradd -m -s /bin/bash ubuntu
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    mkdir -p /home/ubuntu/.ssh
    chown ubuntu:ubuntu /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh
  EOF

  tags = {
    Name = "TP-FINAL-WEB-instance"
  }
}

# EC2 Instance BDD
resource "aws_instance" "TP-FINAL-BDD" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2023
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.TP-FINAL-BDD_subnet.id
  key_name               = aws_key_pair.TP-FINAL_keypair.key_name
  vpc_security_group_ids = [aws_security_group.TP-FINAL_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip
  EOF

  tags = {
    Name = "TP-FINAL-BDD-instance"
  }
}

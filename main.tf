#Create vpc default
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

# Crear Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# Crear tabla de rutas
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main_route_table"
  }
}

# Asociar la tabla de rutas con la subred
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

#create subnet dentro de la vpc
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Asignara ip pública automáticamente

  tags = {
    Name = "main_subnet"
  }
}

# Crear clave para conexión SSH
resource "aws_key_pair" "k8s-ssh" {
  key_name   = "k8s_access"
  public_key = file(var.public_key)
}

resource "aws_security_group" "k8s_security_group" {
  name = "k8s_security_group"
  vpc_id = aws_vpc.main.id
  description = "Allow ssh, http basic web server"

  # Allow access PORT 22
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "k8s_security_group"
  }
}

resource "aws_instance" "ec2_control_plain" {
  ami               = var.ami # Ubuntu 20.04 LTS
  instance_type     = var.instance_type
  key_name          = aws_key_pair.k8s-ssh.key_name
  subnet_id         = aws_subnet.main.id
  #security_groups   = [aws_security_group.k8s_security_group.name] 
  vpc_security_group_ids = [aws_security_group.k8s_security_group.id]
  user_data         = <<-EOF
  #!/bin/bash
  sudo apt-get update -y
  sudo apt install net-tools wget git curl vim -y
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
  sudo apt-get update -y
  sudo apt-get install ca-certificates curl -y
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
  wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.15/cri-dockerd_0.3.15.3-0.ubuntu-jammy_amd64.deb
  sudo dpkg -i cri-dockerd_0.3.15.3-0.ubuntu-jammy_amd64.deb
  sudo apt --fix-broken install
  sudo apt-get install -y apt-transport-https ca-certificates curl gpg
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update -y
  sudo apt-get install -y kubelet kubeadm kubectl -y
  sudo apt-mark hold kubelet kubeadm kubectl -y
  sudo systemctl enable --now kubelet
  echo "overlay" | sudo tee -a /etc/modules-load.d/k8s.conf
  echo "br_netfilter" | sudo tee -a /etc/modules-load.d/k8s.conf
  sudo modprobe overlay -y
  sudo modprobe br_netfilter -y
  echo "net.bridge.bridge-nf-call-iptables  = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
  echo "net.bridge.bridge-nf-call-iptables  = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
  echo "net.ipv4.ip_forward                 = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
  sudo sysctl --system
  sudo hostnamectl set-hostname master-node
  bash
  EOF
  tags = {
    Name = "k8s-carlos-ctrl-poc"
  }
}

resource "aws_instance" "ec2_worker_node" {
  ami               = var.ami # Ubuntu 20.04 LTS
  instance_type     = var.instance_type
  key_name          = aws_key_pair.k8s-ssh.key_name
  subnet_id         = aws_subnet.main.id
  #security_groups   = [aws_security_group.k8s_security_group.name] 
  vpc_security_group_ids = [aws_security_group.k8s_security_group.id]
  user_data         = <<-EOF
  #!/bin/bash
  sudo apt-get update -y
  sudo apt install net-tools wget git curl vim -y
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
  sudo apt-get update -y
  sudo apt-get install ca-certificates curl -y
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
  wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.15/cri-dockerd_0.3.15.3-0.ubuntu-jammy_amd64.deb
  sudo dpkg -i cri-dockerd_0.3.15.3-0.ubuntu-jammy_amd64.deb
  sudo apt --fix-broken install
  sudo apt-get install -y apt-transport-https ca-certificates curl gpg
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update -y
  sudo apt-get install -y kubelet kubeadm kubectl -y
  sudo apt-mark hold kubelet kubeadm kubectl -y
  sudo systemctl enable --now kubelet
  echo "overlay" | sudo tee -a /etc/modules-load.d/k8s.conf
  echo "br_netfilter" | sudo tee -a /etc/modules-load.d/k8s.conf
  sudo modprobe overlay
  sudo modprobe br_netfilter
  echo "net.bridge.bridge-nf-call-iptables  = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
  echo "net.bridge.bridge-nf-call-iptables  = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
  echo "net.ipv4.ip_forward                 = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
  sudo sysctl --system
  sudo hostnamectl set-hostname worker-node
  bash
  EOF
  tags = {
    Name = "k8s-carlos-worker-poc"
  }
}


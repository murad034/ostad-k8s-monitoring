#!/bin/bash

##############################################################################
# EC2 Instance Setup Script
# Description: Prepares Ubuntu EC2 instance for Kubernetes with Minikube
# Author: OSTAD 2025 - Module 7
##############################################################################

set -e  # Exit on error

echo "============================================"
echo "Starting EC2 Instance Setup for Kubernetes"
echo "============================================"

# Update system packages
echo ""
echo "[1/6] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo ""
echo "[2/6] Installing essential packages..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    wget \
    vim \
    htop \
    net-tools

# Install Docker
echo ""
echo "[3/6] Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group
    sudo usermod -aG docker $USER

    # Start and enable Docker
    sudo systemctl enable docker
    sudo systemctl start docker

    echo "Docker installed successfully!"
else
    echo "Docker is already installed"
fi

# Verify Docker installation
docker --version

# Install kubectl
echo ""
echo "[4/6] Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo "kubectl installed successfully!"
else
    echo "kubectl is already installed"
fi

# Verify kubectl installation
kubectl version --client

# Install Helm
echo ""
echo "[5/6] Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "Helm installed successfully!"
else
    echo "Helm is already installed"
fi

# Verify Helm installation
helm version

# Install conntrack (required for Minikube)
echo ""
echo "[6/6] Installing additional dependencies..."
sudo apt install -y conntrack

# Configure system settings for Kubernetes
echo ""
echo "Configuring system settings..."

# Disable swap (required for Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load necessary kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo ""
echo "============================================"
echo "EC2 Setup Complete!"
echo "============================================"
echo ""
echo "Installed components:"
echo "  ✓ Docker: $(docker --version)"
echo "  ✓ kubectl: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
echo "  ✓ Helm: $(helm version --short)"
echo ""
echo "IMPORTANT: You may need to log out and log back in for Docker group changes to take effect."
echo "Or run: newgrp docker"
echo ""
echo "Next step: Run './scripts/02-install-minikube.sh' to install Minikube"
echo ""

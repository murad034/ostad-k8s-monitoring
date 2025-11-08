#!/bin/bash

##############################################################################
# Minikube Installation and Setup Script
# Description: Installs and configures Minikube on EC2 instance
# Author: OSTAD 2025 - Module 7
##############################################################################

set -e  # Exit on error

echo "============================================"
echo "Installing and Configuring Minikube"
echo "============================================"

# Install Minikube
echo ""
echo "[1/3] Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    echo "Minikube installed successfully!"
else
    echo "Minikube is already installed"
fi

# Verify Minikube installation
minikube version

# Start Minikube cluster
echo ""
echo "[2/3] Starting Minikube cluster..."
echo "This may take a few minutes..."

# Start Minikube with specific configuration
minikube start \
    --driver=docker \
    --cpus=2 \
    --memory=4096 \
    --disk-size=20g \
    --kubernetes-version=stable \
    --extra-config=kubelet.housekeeping-interval=10s

echo "Minikube cluster started successfully!"

# Enable addons
echo ""
echo "[3/3] Enabling Minikube addons..."
minikube addons enable metrics-server
minikube addons enable storage-provisioner

echo ""
echo "============================================"
echo "Minikube Setup Complete!"
echo "============================================"
echo ""
echo "Cluster Information:"
minikube status
echo ""
echo "Kubernetes version:"
kubectl version --short
echo ""
echo "Cluster nodes:"
kubectl get nodes
echo ""
echo "System pods:"
kubectl get pods -A
echo ""
echo "Next step: Run './scripts/03-deploy-all.sh' to deploy the monitoring stack"
echo ""

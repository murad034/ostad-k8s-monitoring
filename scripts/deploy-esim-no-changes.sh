#!/bin/bash

# Deploy eSIM Backend WITHOUT Code Changes
# This script deploys your existing backend to Kubernetes

set -e

echo "========================================="
echo "Deploy eSIM Backend - NO CODE CHANGES"
echo "========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if Minikube is running
echo -e "${YELLOW}Step 1: Check Minikube status${NC}"
if ! minikube status &> /dev/null; then
    echo -e "${RED}Minikube is not running!${NC}"
    echo "Starting Minikube..."
    minikube start --driver=docker --memory=3072 --cpus=2
fi

echo -e "${GREEN}✓ Minikube is running${NC}"

# Check if Grafana is running
echo -e "${YELLOW}Step 2: Check Grafana${NC}"
if ! kubectl get svc -n monitoring grafana-simple &> /dev/null; then
    echo "Grafana not found. Deploying standalone Grafana..."
    kubectl create deployment grafana --image=grafana/grafana:latest -n monitoring 2>/dev/null || true
    kubectl expose deployment grafana --port=3000 --target-port=3000 --type=ClusterIP --name=grafana-simple -n monitoring 2>/dev/null || true
    echo "Waiting for Grafana to be ready..."
    kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=120s || echo "Grafana may still be starting..."
    echo -e "${GREEN}✓ Grafana deployed${NC}"
else
    echo -e "${GREEN}✓ Grafana is already running${NC}"
fi

# Verify Docker image
echo -e "${YELLOW}Step 3: Verify Docker image${NC}"
IMAGE_NAME="murad034/esim-backend:v2"
echo "Using image: $IMAGE_NAME"

# Delete existing deployment if exists
echo -e "${YELLOW}Step 4: Clean up existing deployment${NC}"
if kubectl get namespace esim &> /dev/null; then
    echo "Deleting existing esim namespace..."
    kubectl delete namespace esim --wait=true || true
    sleep 5
fi

# Create namespace first
echo -e "${YELLOW}Step 5: Create namespace${NC}"
kubectl create namespace esim 2>/dev/null || echo "Namespace already exists"
kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/esim --timeout=60s
echo -e "${GREEN}✓ Namespace ready${NC}"

# Deploy secrets and ConfigMap
echo -e "${YELLOW}Step 6: Deploy secrets and ConfigMap${NC}"
kubectl apply -f manifests/application/esim-secrets.yaml
echo -e "${GREEN}✓ Secrets applied${NC}"

# Deploy eSIM backend
echo -e "${YELLOW}Step 7: Deploy eSIM backend${NC}"
kubectl apply -f manifests/application/esim-backend-no-changes.yaml

# Wait for pods to be ready
echo -e "${YELLOW}Step 8: Wait for pods to be ready${NC}"
echo "This may take a few minutes..."
kubectl wait --for=condition=ready pod -l app=esim-backend -n esim --timeout=300s || {
    echo -e "${RED}Pods failed to start. Checking status...${NC}"
    kubectl get pods -n esim
    kubectl describe pods -n esim
    exit 1
}

# Get pod status
echo -e "${YELLOW}Step 9: Verify deployment${NC}"
echo ""
echo "Pods:"
kubectl get pods -n esim
echo ""
echo "Services:"
kubectl get svc -n esim
echo ""

# Verify environment variables
echo -e "${YELLOW}Step 10: Verify environment variables${NC}"
POD_NAME=$(kubectl get pods -n esim -l app=esim-backend -o jsonpath='{.items[0].metadata.name}')
echo "Checking environment in pod: $POD_NAME"
kubectl exec -n esim $POD_NAME -- env | grep -E "DB_HOST|DB_PORT|NODE_ENV" || echo "Environment variables loading..."

# Test backend
echo -e "${YELLOW}Step 11: Test backend connection${NC}"
# Check if pod is accessible
kubectl exec -n esim $POD_NAME -- wget -qO- http://localhost:3000 > /dev/null 2>&1 && {
    echo -e "${GREEN}✓ Backend is responding${NC}"
} || {
    echo -e "${YELLOW}⚠ Backend may not be ready yet${NC}"
}

# Show logs
echo -e "${YELLOW}Step 12: Recent logs${NC}"
kubectl logs -n esim -l app=esim-backend --tail=20

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Your eSIM backend is now deployed!"
echo ""
echo "Access your backend:"
echo "  kubectl port-forward -n esim svc/esim-backend 3001:3000 --address='0.0.0.0'"
echo "  Then visit: http://YOUR_EC2_IP:3001"
echo ""
echo "View logs:"
echo "  kubectl logs -n esim -l app=esim-backend -f"
echo ""
echo "Check pod status:"
echo "  kubectl get pods -n esim"
echo ""
echo "Delete deployment:"
echo "  kubectl delete namespace esim"
echo ""
echo "View in Grafana:"
echo "  1. Port forward Grafana:"
echo "     kubectl port-forward -n monitoring svc/grafana-simple 3000:3000 --address='0.0.0.0'"
echo "  2. Open: http://YOUR_EC2_IP:3000"
echo "  3. Login: admin/admin"
echo "  4. Add Prometheus data source: http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
echo "  5. Query metrics:"
echo "     - CPU: sum(rate(container_cpu_usage_seconds_total{namespace=\"esim\"}[5m]))"
echo "     - Memory: sum(container_memory_working_set_bytes{namespace=\"esim\"})"
echo ""

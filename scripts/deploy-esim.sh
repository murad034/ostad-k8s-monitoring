#!/bin/bash

# Deploy eSIM Backend to Kubernetes
# This script deploys the eSIM application with monitoring

set -e

echo "========================================="
echo "Deploying eSIM Backend"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker image exists
echo -e "${YELLOW}Step 1: Verify Docker image${NC}"
read -p "Enter your Docker Hub username: " DOCKER_USERNAME
IMAGE_NAME="${DOCKER_USERNAME}/esim-backend:latest"

echo "Using image: $IMAGE_NAME"
read -p "Have you built and pushed this image to Docker Hub? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Please build and push your Docker image first:${NC}"
    echo "  cd E:/Development/Server/laragon/www/esim/esim-backend"
    echo "  docker build -t $IMAGE_NAME ."
    echo "  docker push $IMAGE_NAME"
    exit 1
fi

# Update deployment with correct image
echo -e "${YELLOW}Step 2: Update deployment manifest${NC}"
sed -i "s|YOUR_DOCKERHUB_USERNAME/esim-backend:latest|${IMAGE_NAME}|g" manifests/application/esim-backend-deployment.yaml

# Create namespace
echo -e "${YELLOW}Step 3: Create eSIM namespace${NC}"
kubectl apply -f manifests/application/esim-backend-deployment.yaml

# Wait for pods
echo -e "${YELLOW}Step 4: Wait for pods to be ready${NC}"
kubectl wait --for=condition=ready pod -l app=esim-backend -n esim --timeout=300s

# Deploy ServiceMonitor
echo -e "${YELLOW}Step 5: Deploy Prometheus ServiceMonitor${NC}"
kubectl apply -f manifests/prometheus/esim-servicemonitor.yaml

# Update Promtail for logs
echo -e "${YELLOW}Step 6: Configure Loki logging${NC}"
kubectl apply -f manifests/loki/esim-promtail-config.yaml

# Restart Promtail to pick up new config
kubectl rollout restart daemonset/promtail -n monitoring 2>/dev/null || echo "Promtail not found, skipping restart"

# Verify deployment
echo -e "${YELLOW}Step 7: Verify deployment${NC}"
echo ""
echo "Pods:"
kubectl get pods -n esim
echo ""
echo "Services:"
kubectl get svc -n esim
echo ""
echo "ServiceMonitor:"
kubectl get servicemonitor -n monitoring | grep esim

# Check if metrics endpoint is accessible
echo -e "${YELLOW}Step 8: Test metrics endpoint${NC}"
POD_NAME=$(kubectl get pods -n esim -l app=esim-backend -o jsonpath='{.items[0].metadata.name}')
echo "Testing metrics from pod: $POD_NAME"
kubectl exec -n esim $POD_NAME -- wget -qO- http://localhost:3000/metrics | head -20

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}eSIM Backend Deployment Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Port forward to access the backend:"
echo "   kubectl port-forward -n esim svc/esim-backend 3001:3000 --address='0.0.0.0'"
echo ""
echo "2. Access services:"
echo "   Backend API: http://YOUR_EC2_IP:3001"
echo "   Health: http://YOUR_EC2_IP:3001/health"
echo "   Metrics: http://YOUR_EC2_IP:3001/metrics"
echo ""
echo "3. Check Prometheus targets (should see esim-backend):"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 --address='0.0.0.0'"
echo "   Open: http://YOUR_EC2_IP:9090/targets"
echo ""
echo "4. View metrics in Grafana:"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'"
echo "   Open: http://YOUR_EC2_IP:3000"
echo ""

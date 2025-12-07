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

# Deploy monitoring namespace
echo -e "${YELLOW}Step 2: Create monitoring namespace${NC}"
kubectl create namespace monitoring 2>/dev/null || echo "Namespace monitoring already exists"
echo -e "${GREEN}✓ Monitoring namespace ready${NC}"

# Deploy Loki for log aggregation
echo -e "${YELLOW}Step 3: Deploy Loki${NC}"
if ! kubectl get statefulset -n monitoring loki &> /dev/null; then
    echo "Deploying Loki..."
    kubectl apply -f manifests/loki/loki.yaml
    echo "Waiting for Loki to be ready..."
    sleep 10
    kubectl wait --for=condition=ready pod -l app=loki -n monitoring --timeout=120s || echo "Loki may still be starting..."
    echo -e "${GREEN}✓ Loki deployed${NC}"
else
    echo -e "${GREEN}✓ Loki is already running${NC}"
fi

# Deploy Promtail for log collection (Minikube-compatible version)
echo -e "${YELLOW}Step 4: Deploy Promtail (Minikube Docker version)${NC}"
if ! kubectl get daemonset -n monitoring promtail &> /dev/null; then
    echo "Deploying Promtail for Minikube Docker runtime..."
    # Use the Minikube-compatible Promtail configuration
    if [ -f "manifests/loki/promtail-minikube.yaml" ]; then
        kubectl apply -f manifests/loki/promtail-minikube.yaml
    else
        echo "Warning: promtail-minikube.yaml not found, using standard promtail.yaml"
        kubectl apply -f manifests/loki/promtail.yaml
    fi
    echo "Waiting for Promtail to be ready..."
    sleep 10
    kubectl wait --for=condition=ready pod -l app=promtail -n monitoring --timeout=120s || echo "Promtail may still be starting..."
    echo -e "${GREEN}✓ Promtail deployed${NC}"
else
    echo -e "${GREEN}✓ Promtail is already running${NC}"
fi

# Check if Grafana is running
echo -e "${YELLOW}Step 5: Deploy Grafana${NC}"
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
echo -e "${YELLOW}Step 6: Verify Docker image${NC}"
IMAGE_NAME="murad034/esim-backend:v2"
echo "Using image: $IMAGE_NAME"

# Delete existing deployment if exists
echo -e "${YELLOW}Step 7: Clean up existing esim deployment${NC}"
if kubectl get namespace esim &> /dev/null; then
    echo "Deleting existing esim namespace..."
    kubectl delete namespace esim --wait=true || true
    sleep 5
fi

# Create namespace first
echo -e "${YELLOW}Step 8: Create esim namespace${NC}"
kubectl create namespace esim 2>/dev/null || echo "Namespace already exists"
kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/esim --timeout=60s
echo -e "${GREEN}✓ Namespace ready${NC}"

# Deploy secrets and ConfigMap
echo -e "${YELLOW}Step 9: Deploy secrets and ConfigMap${NC}"
kubectl apply -f manifests/application/esim-secrets.yaml
echo -e "${GREEN}✓ Secrets applied${NC}"

# Deploy eSIM backend
echo -e "${YELLOW}Step 10: Deploy eSIM backend${NC}"
kubectl apply -f manifests/application/esim-backend-no-changes.yaml

# Wait for pods to be ready
echo -e "${YELLOW}Step 11: Wait for pods to be ready${NC}"
echo "This may take a few minutes..."

# First wait for pods to exist
echo "Waiting for pods to be created..."
for i in {1..30}; do
    POD_COUNT=$(kubectl get pods -n esim -l app=esim-backend --no-headers 2>/dev/null | wc -l)
    if [ "$POD_COUNT" -gt 0 ]; then
        echo "Pod found!"
        break
    fi
    echo "Waiting for pod creation... ($i/30)"
    sleep 2
done

# Then wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=esim-backend -n esim --timeout=300s || {
    echo -e "${RED}Pods failed to start. Checking status...${NC}"
    kubectl get pods -n esim
    echo ""
    echo "Pod details:"
    kubectl describe pods -n esim
    echo ""
    echo "Recent events:"
    kubectl get events -n esim --sort-by='.lastTimestamp' | tail -20
    exit 1
}

# Get pod status
echo -e "${YELLOW}Step 12: Verify deployment${NC}"
echo ""
echo "Pods:"
kubectl get pods -n esim
echo ""
echo "Services:"
kubectl get svc -n esim
echo ""

# Verify environment variables
echo -e "${YELLOW}Step 13: Verify environment variables${NC}"
POD_NAME=$(kubectl get pods -n esim -l app=esim-backend -o jsonpath='{.items[0].metadata.name}')
echo "Checking environment in pod: $POD_NAME"
kubectl exec -n esim $POD_NAME -- env | grep -E "DB_HOST|DB_PORT|NODE_ENV" || echo "Environment variables loading..."

# Test backend
echo -e "${YELLOW}Step 14: Test backend connection${NC}"
# Check if pod is accessible
kubectl exec -n esim $POD_NAME -- wget -qO- http://localhost:3000 > /dev/null 2>&1 && {
    echo -e "${GREEN}✓ Backend is responding${NC}"
} || {
    echo -e "${YELLOW}⚠ Backend may not be ready yet${NC}"
}

# Show logs
echo -e "${YELLOW}Step 15: Recent backend logs${NC}"
kubectl logs -n esim -l app=esim-backend --tail=20

# Verify monitoring stack
echo ""
echo -e "${YELLOW}Step 16: Verify monitoring stack${NC}"
echo "Monitoring pods:"
kubectl get pods -n monitoring
echo ""

# Wait for logs to be collected
echo -e "${YELLOW}Step 17: Wait for Loki to collect logs${NC}"
echo "Waiting 30 seconds for Promtail to collect and send logs to Loki..."
sleep 30

# Check if Loki has esim logs
echo -e "${YELLOW}Step 18: Verify Loki log collection${NC}"
ESIM_IN_LOKI=$(kubectl exec -n monitoring loki-0 -- wget -qO- 'http://localhost:3100/loki/api/v1/label/namespace/values' 2>/dev/null | grep -c esim || echo "0")

if [ "$ESIM_IN_LOKI" -gt 0 ]; then
    echo -e "${GREEN}✅ SUCCESS! Loki is collecting logs from esim namespace!${NC}"
else
    echo -e "${YELLOW}⚠️  Loki not yet receiving esim logs. This is normal if just deployed.${NC}"
    echo "   Logs should appear within 1-2 minutes."
    echo ""
    echo "   Troubleshoot with:"
    echo "   kubectl logs -n monitoring -l app=promtail --tail=50"
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Your eSIM backend and monitoring stack are now deployed!"
echo ""
echo "📊 MONITORING SETUP:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Port Forward Services:"
echo "   Backend:"
echo "     kubectl port-forward -n esim svc/esim-backend 3001:3000 --address='0.0.0.0'"
echo ""
echo "   Grafana:"
echo "     kubectl port-forward -n monitoring svc/grafana-simple 3000:3000 --address='0.0.0.0'"
echo ""
echo "2. Access URLs:"
echo "   Backend API: http://YOUR_EC2_IP:3001"
echo "   Grafana:     http://YOUR_EC2_IP:3000 (admin/admin)"
echo ""
echo "3. Configure Grafana Data Sources:"
echo "   "
echo "   📈 Prometheus (Metrics):"
echo "      URL: http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
echo "      "
echo "   📝 Loki (Logs):"
echo "      URL: http://loki.monitoring.svc.cluster.local:3100"
echo ""
echo "4. Sample Queries:"
echo "   "
echo "   Prometheus Metrics:"
echo "     CPU:    sum(rate(container_cpu_usage_seconds_total{namespace=\"esim\"}[5m]))"
echo "     Memory: sum(container_memory_working_set_bytes{namespace=\"esim\"})"
echo "   "
echo "   Loki Logs:"
echo "     All logs:    {namespace=\"esim\"}"
echo "     Backend:     {namespace=\"esim\", app=\"esim-backend\"}"
echo "     Errors only: {namespace=\"esim\"} |~ \"ERROR|error\""
echo ""
echo "5. Useful Commands:"
echo "   View logs:        kubectl logs -n esim -l app=esim-backend -f"
echo "   Check pods:       kubectl get pods -n esim"
echo "   Check monitoring: kubectl get pods -n monitoring"
echo "   Delete all:       kubectl delete namespace esim"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔍 TROUBLESHOOTING:"
echo ""
echo "If Loki shows no logs for esim namespace:"
echo "  1. Check Promtail: kubectl logs -n monitoring -l app=promtail --tail=100"
echo "  2. Verify namespace: kubectl exec -n monitoring loki-0 -- wget -qO- 'http://localhost:3100/loki/api/v1/label/namespace/values'"
echo "  3. Restart Promtail: kubectl delete pod -n monitoring -l app=promtail"
echo ""

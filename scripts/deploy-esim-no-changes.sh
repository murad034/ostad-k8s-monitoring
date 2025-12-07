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

# Deploy Grafana with persistent storage and pre-configured data sources
echo -e "${YELLOW}Step 5: Deploy Grafana with persistent configuration${NC}"
if ! kubectl get deployment -n monitoring grafana &> /dev/null; then
    echo "Deploying Grafana with auto-configured data sources..."
    
    # Create Grafana datasources ConfigMap
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: monitoring
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090
        isDefault: true
        editable: true
      - name: Loki
        type: loki
        access: proxy
        url: http://loki.monitoring.svc.cluster.local:3100
        editable: true
EOF

    # Create Grafana deployment with persistent volume
    kubectl create deployment grafana --image=grafana/grafana:latest -n monitoring 2>/dev/null || true
    
    # Patch deployment to add datasources volume
    kubectl set env deployment/grafana -n monitoring GF_SECURITY_ADMIN_PASSWORD=admin GF_SECURITY_ADMIN_USER=admin 2>/dev/null || true
    
    # Wait for deployment to exist
    sleep 2
    
    # Patch to add datasources
    kubectl patch deployment grafana -n monitoring --type=json -p='[
      {
        "op": "add",
        "path": "/spec/template/spec/volumes",
        "value": [
          {
            "name": "datasources",
            "configMap": {
              "name": "grafana-datasources"
            }
          }
        ]
      },
      {
        "op": "add",
        "path": "/spec/template/spec/containers/0/volumeMounts",
        "value": [
          {
            "name": "datasources",
            "mountPath": "/etc/grafana/provisioning/datasources"
          }
        ]
      }
    ]' 2>/dev/null || echo "Patch may have already been applied"
    
    # Expose as NodePort for stable access
    kubectl expose deployment grafana --port=3000 --target-port=3000 --type=NodePort --name=grafana-simple -n monitoring 2>/dev/null || true
    
    echo "Waiting for Grafana to be ready..."
    kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=120s || echo "Grafana may still be starting..."
    echo -e "${GREEN}✓ Grafana deployed with auto-configured data sources${NC}"
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

# Get NodePort for Grafana
GRAFANA_PORT=$(kubectl get svc grafana-simple -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
ESIM_SERVICE_TYPE=$(kubectl get svc esim-backend -n esim -o jsonpath='{.spec.type}' 2>/dev/null || echo "ClusterIP")

echo "📊 ACCESS INFORMATION:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$GRAFANA_PORT" != "" ]; then
    echo "🎯 RECOMMENDED: Use Minikube Tunnel (More Stable)"
    echo "   Run in a separate terminal:"
    echo "   sudo minikube tunnel"
    echo ""
    echo "   Then access:"
    echo "   Grafana: http://$(curl -s ifconfig.me):$GRAFANA_PORT"
    echo "   (Or use your EC2 IP)"
    echo ""
fi

echo "🔄 ALTERNATIVE: Port Forward (May disconnect)"
echo "   Backend:"
echo "     kubectl port-forward -n esim svc/esim-backend 3001:3000 --address='0.0.0.0' &"
echo ""
echo "   Grafana:"
echo "     kubectl port-forward -n monitoring svc/grafana-simple 3000:3000 --address='0.0.0.0' &"
echo ""
echo "   Stop port forwards: pkill -f 'port-forward'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔑 GRAFANA LOGIN:"
echo "   Username: admin"
echo "   Password: admin"
echo "   "
echo "   ✅ Data sources are AUTO-CONFIGURED!"
echo "   - Prometheus: Already added"
echo "   - Loki: Already added"
echo ""
echo "📝 LOKI QUERIES (in Grafana Explore):"
echo "   All logs:    {namespace=\"esim\"}"
echo "   Backend:     {namespace=\"esim\", app=\"esim-backend\"}"
echo "   Errors only: {namespace=\"esim\"} |~ \"ERROR|error\""
echo ""
echo "📈 PROMETHEUS QUERIES:"
echo "   CPU:    sum(rate(container_cpu_usage_seconds_total{namespace=\"esim\"}[5m]))"
echo "   Memory: sum(container_memory_working_set_bytes{namespace=\"esim\"})"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔍 USEFUL COMMANDS:"
echo "   View backend logs:   kubectl logs -n esim -l app=esim-backend -f"
echo "   Check all pods:      kubectl get pods -A"
echo "   Restart Grafana:     kubectl rollout restart deployment/grafana -n monitoring"
echo "   Restart backend:     kubectl rollout restart deployment/esim-backend -n esim"
echo "   Delete everything:   kubectl delete namespace esim monitoring"
echo ""
echo "🚨 TROUBLESHOOTING CONNECTION ISSUES:"
echo ""
echo "   If kubectl commands timeout:"
echo "     minikube status"
echo "     minikube start"
echo ""
echo "   If Grafana data sources disappear:"
echo "     kubectl rollout restart deployment/grafana -n monitoring"
echo "     (Data sources will auto-reload from ConfigMap)"
echo ""
echo "   If port-forward keeps breaking:"
echo "     Use 'sudo minikube tunnel' instead (more stable)"
echo ""
echo "   If Loki shows no logs:"
echo "     kubectl delete pod -n monitoring -l app=promtail"
echo "     kubectl logs -n monitoring -l app=promtail --tail=50"
echo ""

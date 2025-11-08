#!/bin/bash

##############################################################################
# Deploy All Components Script
# Description: Deploys application, Prometheus, Grafana, and Loki
# Author: OSTAD 2025 - Module 7
##############################################################################

set -e  # Exit on error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo "Deploying Kubernetes Monitoring Stack"
echo "============================================"

# Check if cluster is running
echo ""
echo "Checking cluster status..."
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Kubernetes cluster is not running!"
    echo "Please start Minikube first: minikube start"
    exit 1
fi

echo "Cluster is running!"

# Step 1: Create namespaces
echo ""
echo "[1/5] Creating namespaces..."
kubectl apply -f "$PROJECT_ROOT/manifests/namespace/"

# Wait for namespaces to be ready
sleep 5

# Step 2: Deploy sample application
echo ""
echo "[2/5] Deploying sample Nginx application..."
kubectl apply -f "$PROJECT_ROOT/manifests/application/"

# Wait for application to be ready
echo "Waiting for application pods to be ready..."
kubectl wait --for=condition=ready pod -l app=nginx -n application --timeout=120s

# Step 3: Install Prometheus and Grafana using Helm
echo ""
echo "[3/5] Installing Prometheus and Grafana..."

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Check if already installed
if helm list -n monitoring | grep -q prometheus; then
    echo "Prometheus stack already installed. Upgrading..."
    helm upgrade prometheus prometheus-community/kube-prometheus-stack \
        -n monitoring \
        -f "$PROJECT_ROOT/manifests/prometheus/values.yaml"
else
    echo "Installing Prometheus stack..."
    helm install prometheus prometheus-community/kube-prometheus-stack \
        -n monitoring \
        -f "$PROJECT_ROOT/manifests/prometheus/values.yaml"
fi

# Wait for Prometheus stack to be ready
echo "Waiting for Prometheus stack to be ready (this may take a few minutes)..."
sleep 30
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s

# Step 4: Deploy Loki
echo ""
echo "[4/5] Deploying Loki..."
kubectl apply -f "$PROJECT_ROOT/manifests/loki/"

# Wait for Loki to be ready
echo "Waiting for Loki to be ready..."
sleep 20
kubectl wait --for=condition=ready pod -l app=loki -n monitoring --timeout=180s
kubectl wait --for=condition=ready pod -l app=promtail -n monitoring --timeout=180s

# Step 5: Configure Grafana dashboards
echo ""
echo "[5/5] Configuring Grafana dashboards..."
kubectl apply -f "$PROJECT_ROOT/manifests/grafana/"

echo ""
echo "============================================"
echo "Deployment Complete!"
echo "============================================"
echo ""
echo "Cluster Status:"
echo "---------------"
kubectl get nodes
echo ""
echo "All Pods:"
echo "---------"
kubectl get pods -A
echo ""
echo "Services:"
echo "---------"
kubectl get svc -A
echo ""
echo "============================================"
echo "Access Information"
echo "============================================"
echo ""

# Get Grafana password
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana \
    -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "Grafana Credentials:"
echo "  URL: http://<EC2-PUBLIC-IP>:3000"
echo "  Username: admin"
echo "  Password: $GRAFANA_PASSWORD"
echo ""
echo "To access Grafana, run:"
echo "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'"
echo ""
echo "To access Prometheus, run:"
echo "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 --address='0.0.0.0'"
echo ""
echo "To access the Nginx application, run:"
echo "  kubectl port-forward -n application svc/nginx-service 8080:80 --address='0.0.0.0'"
echo ""
echo "============================================"
echo "Next Steps"
echo "============================================"
echo "1. Port forward the services (see commands above)"
echo "2. Log in to Grafana"
echo "3. Add Loki as a data source:"
echo "   URL: http://loki.monitoring.svc.cluster.local:3100"
echo "4. Import the dashboards from the dashboards/ folder"
echo "5. Take screenshots for your report"
echo ""

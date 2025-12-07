#!/bin/bash

# Fix Minikube and Grafana Stability Issues
# Run this when facing connection problems or Grafana data sources disappearing

echo "========================================"
echo "Fixing Stability Issues"
echo "========================================"
echo ""

# Check Minikube status
echo "1. Checking Minikube status..."
if ! minikube status | grep -q "Running"; then
    echo "⚠️  Minikube not running properly. Restarting..."
    minikube stop
    sleep 5
    minikube start --driver=docker --memory=3072 --cpus=2
    echo "✓ Minikube restarted"
else
    echo "✓ Minikube is running"
fi

# Check Docker resource usage
echo ""
echo "2. Checking Docker resources..."
docker system df
echo ""

# Clean up if needed
read -p "Clean up unused Docker resources? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker system prune -f
    echo "✓ Docker cleaned up"
fi

# Restart problematic pods
echo ""
echo "3. Restarting Grafana to reload data sources..."
kubectl rollout restart deployment/grafana -n monitoring 2>/dev/null || echo "Grafana not found"
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=60s 2>/dev/null || echo "Waiting for Grafana..."

echo ""
echo "4. Checking if data sources ConfigMap exists..."
if kubectl get configmap grafana-datasources -n monitoring &>/dev/null; then
    echo "✓ Data sources ConfigMap exists"
else
    echo "⚠️  Creating data sources ConfigMap..."
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
    echo "✓ ConfigMap created"
    kubectl rollout restart deployment/grafana -n monitoring
fi

echo ""
echo "5. Restarting Promtail to refresh log collection..."
kubectl delete pod -n monitoring -l app=promtail 2>/dev/null || echo "Promtail not found"
sleep 5

echo ""
echo "6. Current pod status:"
echo ""
echo "Monitoring:"
kubectl get pods -n monitoring
echo ""
echo "eSIM:"
kubectl get pods -n esim
echo ""

echo "7. Services and ports:"
GRAFANA_PORT=$(kubectl get svc grafana-simple -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ "$GRAFANA_PORT" != "" ]; then
    echo "✓ Grafana NodePort: $GRAFANA_PORT"
    echo ""
    echo "Access via minikube tunnel:"
    echo "  sudo minikube tunnel"
    echo "  Then: http://YOUR_EC2_IP:$GRAFANA_PORT"
else
    echo "⚠️  Grafana service not found"
fi

echo ""
echo "========================================"
echo "Stability Check Complete!"
echo "========================================"
echo ""
echo "To access services reliably:"
echo ""
echo "Option 1 (RECOMMENDED - Most Stable):"
echo "  sudo minikube tunnel"
echo "  Keep this running in background"
echo ""
echo "Option 2 (If tunnel doesn't work):"
echo "  kubectl port-forward -n monitoring svc/grafana-simple 3000:3000 --address='0.0.0.0'"
echo ""
echo "If connection keeps breaking:"
echo "  1. Check EC2 memory: free -h"
echo "  2. Check Docker: docker ps"
echo "  3. Restart Minikube: minikube stop && minikube start"
echo ""

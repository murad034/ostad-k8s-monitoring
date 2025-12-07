#!/bin/bash

echo "=========================================="
echo "Fix Promtail Configuration"
echo "=========================================="
echo ""

echo "1. Deleting old Promtail ConfigMap..."
kubectl delete configmap promtail-config -n monitoring 2>/dev/null || echo "  (ConfigMap doesn't exist yet)"

echo ""
echo "2. Applying updated Promtail configuration..."
kubectl apply -f manifests/loki/promtail-minikube.yaml

echo ""
echo "3. Restarting Promtail pod to pick up new config..."
kubectl delete pod -n monitoring -l app=promtail

echo ""
echo "4. Waiting for new Promtail pod to start..."
kubectl wait --for=condition=Ready pod -l app=promtail -n monitoring --timeout=60s

echo ""
echo "5. Checking Promtail pod status..."
kubectl get pods -n monitoring -l app=promtail

echo ""
echo "6. Checking Promtail logs (last 20 lines)..."
sleep 5
kubectl logs -n monitoring -l app=promtail --tail=20

echo ""
echo "7. Verifying Docker container access..."
kubectl exec -n monitoring -l app=promtail -- ls -la /var/lib/docker/containers/ | head -10

echo ""
echo "8. Checking ConfigMap was applied..."
kubectl get configmap promtail-config -n monitoring -o yaml | grep -A 5 "scrape_configs"

echo ""
echo "=========================================="
echo "Configuration Updated!"
echo "=========================================="
echo ""
echo "Wait 30 seconds, then check if Loki is receiving logs:"
echo "  kubectl exec -n monitoring loki-0 -- wget -qO- 'http://localhost:3100/loki/api/v1/label/namespace/values'"
echo ""
echo "Should see: esim in the list"
echo ""

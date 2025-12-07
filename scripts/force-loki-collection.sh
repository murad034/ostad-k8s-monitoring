#!/bin/bash

# Force Loki to Collect Logs - Quick Fix

echo "=========================================="
echo "Force Loki Log Collection"
echo "=========================================="
echo ""

# Step 1: Restart Promtail to refresh discovery
echo "1. Restarting Promtail to refresh pod discovery..."
PROMTAIL_POD=$(kubectl get pod -n monitoring -l app=promtail -o jsonpath='{.items[0].metadata.name}')
if [ -n "$PROMTAIL_POD" ]; then
    echo "Deleting pod: $PROMTAIL_POD"
    kubectl delete pod -n monitoring $PROMTAIL_POD
    echo "Waiting for new pod to start..."
    sleep 10
    kubectl wait --for=condition=ready pod -l app=promtail -n monitoring --timeout=60s
    NEW_PROMTAIL=$(kubectl get pod -n monitoring -l app=promtail -o jsonpath='{.items[0].metadata.name}')
    echo "✓ New Promtail pod: $NEW_PROMTAIL"
else
    echo "✗ Promtail pod not found"
    exit 1
fi

# Step 2: Generate test logs
echo ""
echo "2. Generating test logs from backend..."
for i in {1..5}; do
    curl -s http://localhost:3001/api/esim/plans > /dev/null 2>&1 && echo "  Request $i sent" || echo "  Request $i failed (backend may not be port-forwarded)"
    sleep 1
done

# Step 3: Wait for Promtail to collect and send logs
echo ""
echo "3. Waiting 30 seconds for Promtail to collect logs..."
sleep 30

# Step 4: Check if logs are in Loki
echo ""
echo "4. Checking if Loki received logs..."
NAMESPACES=$(kubectl exec -n monitoring loki-0 -- wget -qO- 'http://localhost:3100/loki/api/v1/label/namespace/values' 2>/dev/null)

if echo "$NAMESPACES" | grep -q "esim"; then
    echo "✅ SUCCESS! Loki is now receiving logs from esim namespace!"
    echo ""
    echo "Namespaces in Loki:"
    echo "$NAMESPACES" | grep -o '"[^"]*"' | tr -d '"'
    echo ""
    echo "Now you can query in Grafana Explore:"
    echo "  {namespace=\"esim\"}"
    echo "  {namespace=\"esim\", app=\"esim-backend\"}"
else
    echo "⚠️  Still no esim logs in Loki"
    echo ""
    echo "Current namespaces in Loki:"
    echo "$NAMESPACES" | grep -o '"[^"]*"' | tr -d '"'
    echo ""
    echo "Troubleshooting:"
    echo ""
    
    # Check Promtail logs
    echo "Checking Promtail logs for issues..."
    kubectl logs -n monitoring -l app=promtail --tail=50 | grep -i "error\|warn\|esim" || echo "No errors found"
    echo ""
    
    # Check if backend pod exists
    ESIM_POD=$(kubectl get pod -n esim -l app=esim-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -z "$ESIM_POD" ]; then
        echo "✗ eSIM backend pod not found!"
        echo "   Deploy backend first: ./scripts/deploy-esim-no-changes.sh"
    else
        echo "✓ eSIM backend pod exists: $ESIM_POD"
        
        # Check if backend has logs
        LOG_COUNT=$(kubectl logs -n esim $ESIM_POD --tail=10 2>/dev/null | wc -l)
        if [ "$LOG_COUNT" -gt 0 ]; then
            echo "✓ Backend is generating logs"
        else
            echo "✗ Backend has no logs - it may not be running properly"
        fi
    fi
    
    echo ""
    echo "Next steps:"
    echo "1. Check Promtail can access Docker:"
    echo "   kubectl exec -n monitoring -l app=promtail -- ls /var/run/docker.sock"
    echo ""
    echo "2. Check Promtail configuration:"
    echo "   kubectl get configmap promtail-config -n monitoring -o yaml"
    echo ""
    echo "3. Re-run diagnostic:"
    echo "   ./scripts/diagnose-loki.sh"
fi

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="

#!/bin/bash

# Diagnose and Fix Loki Log Collection Issues

echo "=========================================="
echo "Loki Log Collection Diagnostic"
echo "=========================================="
echo ""

# Step 1: Check if Loki is running
echo "1. Checking Loki status..."
if kubectl get pod -n monitoring loki-0 &>/dev/null; then
    LOKI_STATUS=$(kubectl get pod -n monitoring loki-0 -o jsonpath='{.status.phase}')
    echo "✓ Loki pod exists (Status: $LOKI_STATUS)"
else
    echo "✗ Loki pod not found!"
    exit 1
fi

# Step 2: Check if Promtail is running
echo ""
echo "2. Checking Promtail status..."
PROMTAIL_POD=$(kubectl get pod -n monitoring -l app=promtail -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$PROMTAIL_POD" ]; then
    PROMTAIL_STATUS=$(kubectl get pod -n monitoring -l app=promtail -o jsonpath='{.items[0].status.phase}')
    echo "✓ Promtail pod: $PROMTAIL_POD (Status: $PROMTAIL_STATUS)"
else
    echo "✗ Promtail pod not found!"
    exit 1
fi

# Step 3: Check esim backend is running
echo ""
echo "3. Checking esim backend status..."
ESIM_POD=$(kubectl get pod -n esim -l app=esim-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$ESIM_POD" ]; then
    ESIM_STATUS=$(kubectl get pod -n esim -l app=esim-backend -o jsonpath='{.items[0].status.phase}')
    echo "✓ eSIM backend pod: $ESIM_POD (Status: $ESIM_STATUS)"
else
    echo "✗ eSIM backend pod not found!"
    exit 1
fi

# Step 4: Check if backend is generating logs
echo ""
echo "4. Checking if backend is generating logs..."
LOG_COUNT=$(kubectl logs -n esim $ESIM_POD --tail=5 2>/dev/null | wc -l)
if [ "$LOG_COUNT" -gt 0 ]; then
    echo "✓ Backend is generating logs ($LOG_COUNT recent lines)"
    echo ""
    echo "Recent backend logs:"
    kubectl logs -n esim $ESIM_POD --tail=5
else
    echo "✗ No logs found from backend"
fi

# Step 5: Check Promtail can access Docker socket
echo ""
echo "5. Checking Promtail Docker access..."
kubectl exec -n monitoring $PROMTAIL_POD -- ls -la /var/run/docker.sock 2>/dev/null && echo "✓ Docker socket accessible" || echo "✗ Docker socket NOT accessible"
kubectl exec -n monitoring $PROMTAIL_POD -- ls /var/lib/docker/containers 2>/dev/null | head -3 && echo "✓ Docker containers accessible" || echo "✗ Docker containers NOT accessible"

# Step 6: Check Promtail logs for errors
echo ""
echo "6. Checking Promtail logs for errors..."
echo "Recent Promtail logs:"
kubectl logs -n monitoring $PROMTAIL_POD --tail=30 | grep -E "error|Error|ERROR|esim|warn" || echo "No errors or esim references found"

# Step 7: Check what namespaces Loki knows about
echo ""
echo "7. Querying Loki for known namespaces..."
NAMESPACES=$(kubectl exec -n monitoring loki-0 -- wget -qO- 'http://localhost:3100/loki/api/v1/label/namespace/values' 2>/dev/null)
echo "Namespaces in Loki:"
echo "$NAMESPACES" | grep -o '"[^"]*"' | tr -d '"' | sort | uniq

if echo "$NAMESPACES" | grep -q "esim"; then
    echo "✓ esim namespace found in Loki!"
else
    echo "✗ esim namespace NOT found in Loki"
fi

# Step 8: Check what apps Loki knows about
echo ""
echo "8. Querying Loki for known apps..."
APPS=$(kubectl exec -n monitoring loki-0 -- wget -qO- 'http://localhost:3100/loki/api/v1/label/app/values' 2>/dev/null)
echo "Apps in Loki:"
echo "$APPS" | grep -o '"[^"]*"' | tr -d '"' | sort | uniq

# Step 9: Try to query actual logs
echo ""
echo "9. Testing Loki query for esim logs..."
QUERY_RESULT=$(kubectl exec -n monitoring loki-0 -- wget -qO- 'http://localhost:3100/loki/api/v1/query_range?query={namespace="esim"}&limit=10' 2>/dev/null)
LOG_LINES=$(echo "$QUERY_RESULT" | grep -o '"values":\[\[' | wc -l)

if [ "$LOG_LINES" -gt 0 ]; then
    echo "✓ Found logs in Loki for esim namespace!"
else
    echo "✗ No logs found in Loki query"
    echo ""
    echo "Query response:"
    echo "$QUERY_RESULT" | jq . 2>/dev/null || echo "$QUERY_RESULT"
fi

# Step 10: Recommendations
echo ""
echo "=========================================="
echo "DIAGNOSIS SUMMARY"
echo "=========================================="
echo ""

if echo "$NAMESPACES" | grep -q "esim"; then
    echo "✅ SUCCESS: Loki is collecting logs from esim namespace!"
    echo ""
    echo "Use these queries in Grafana Explore:"
    echo "  {namespace=\"esim\"}"
    echo "  {namespace=\"esim\", app=\"esim-backend\"}"
    echo "  {namespace=\"esim\"} |= \"error\""
else
    echo "⚠️  ISSUE: Loki is NOT collecting esim logs"
    echo ""
    echo "Possible causes:"
    echo ""
    
    # Check if Promtail can access logs
    if ! kubectl exec -n monitoring $PROMTAIL_POD -- ls /var/run/docker.sock &>/dev/null; then
        echo "1. ✗ Promtail cannot access Docker socket"
        echo "   Fix: Redeploy Promtail with Docker socket mount"
        echo "   kubectl delete -f manifests/loki/promtail-minikube.yaml"
        echo "   kubectl apply -f manifests/loki/promtail-minikube.yaml"
    fi
    
    # Check if pods are old
    PROMTAIL_AGE=$(kubectl get pod -n monitoring $PROMTAIL_POD -o jsonpath='{.metadata.creationTimestamp}')
    ESIM_AGE=$(kubectl get pod -n esim $ESIM_POD -o jsonpath='{.metadata.creationTimestamp}')
    echo ""
    echo "2. Pod ages:"
    echo "   Promtail created: $PROMTAIL_AGE"
    echo "   eSIM backend created: $ESIM_AGE"
    echo ""
    echo "   If Promtail is older than backend, it may not have discovered the pod yet."
    echo "   Fix: kubectl delete pod -n monitoring $PROMTAIL_POD"
    
    echo ""
    echo "3. Generate test logs and wait:"
    echo "   curl http://localhost:3001/api/esim/plans"
    echo "   sleep 60"
    echo "   Then re-run this diagnostic"
fi

echo ""
echo "=========================================="
echo "QUICK FIXES"
echo "=========================================="
echo ""
echo "1. Restart Promtail:"
echo "   kubectl delete pod -n monitoring $PROMTAIL_POD"
echo ""
echo "2. Generate test traffic:"
echo "   curl http://localhost:3001/api/esim/plans"
echo ""
echo "3. Check Promtail is collecting:"
echo "   kubectl logs -n monitoring $PROMTAIL_POD -f | grep esim"
echo ""
echo "4. Verify in Grafana:"
echo "   Query: {namespace=\"esim\"}"
echo "   ⚠️  Do NOT use: {app=~\".*\"} - this causes the error you saw"
echo ""

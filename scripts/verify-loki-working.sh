#!/bin/bash

echo "=========================================="
echo "Verify Loki Log Collection"
echo "=========================================="
echo ""

echo "1. Checking Promtail pod status..."
kubectl get pods -n monitoring -l app=promtail
PROMTAIL_POD=$(kubectl get pod -n monitoring -l app=promtail -o jsonpath='{.items[0].metadata.name}')
echo "   Using pod: $PROMTAIL_POD"

echo ""
echo "2. Checking if Promtail can access Docker containers..."
echo "   Docker socket:"
kubectl exec -n monitoring $PROMTAIL_POD -- ls -la /var/run/docker.sock 2>/dev/null && echo "   ✓ Docker socket accessible" || echo "   ✗ Docker socket NOT accessible"
echo ""
echo "   Docker containers directory:"
CONTAINER_COUNT=$(kubectl exec -n monitoring $PROMTAIL_POD -- sh -c 'ls -1 /var/lib/docker/containers/ 2>/dev/null | wc -l')
echo "   Found $CONTAINER_COUNT containers"
if [ "$CONTAINER_COUNT" -gt 0 ]; then
    echo "   ✓ Docker containers accessible"
    echo ""
    echo "   First 3 containers:"
    kubectl exec -n monitoring $PROMTAIL_POD -- ls -1 /var/lib/docker/containers/ | head -3
else
    echo "   ✗ Cannot access Docker containers"
fi

echo ""
echo "3. Checking Promtail logs for errors..."
echo "   Recent errors (if any):"
kubectl logs -n monitoring $PROMTAIL_POD --tail=100 | grep -i "error" | tail -5 || echo "   ✓ No recent errors"

echo ""
echo "4. Checking Promtail logs for success messages..."
echo "   Recent activity:"
kubectl logs -n monitoring $PROMTAIL_POD --tail=50 | grep -E "(Seeked|Starting|targets)" | tail -5

echo ""
echo "5. Checking what namespaces Loki knows about..."
echo "   Querying Loki API..."
NAMESPACES=$(kubectl exec -n monitoring loki-0 -- wget -qO- 'http://localhost:3100/loki/api/v1/label/namespace/values' 2>/dev/null)
echo "$NAMESPACES" | grep -q "esim" && echo "   ✓ esim namespace FOUND in Loki!" || echo "   ✗ esim namespace NOT in Loki yet"
echo ""
echo "   All namespaces in Loki:"
echo "$NAMESPACES" | grep -v "status\|success" | sed 's/^/   /'

echo ""
echo "6. Checking for actual esim logs in Loki..."
ESIM_LOGS=$(kubectl exec -n monitoring loki-0 -- wget -qO- 'http://localhost:3100/loki/api/v1/query_range?query=%7Bnamespace%3D%22esim%22%7D&limit=5' 2>/dev/null)
LOG_COUNT=$(echo "$ESIM_LOGS" | grep -o '"result":\[' | wc -l)

if echo "$ESIM_LOGS" | grep -q '"result":\[\]'; then
    echo "   ✗ No logs found yet"
elif echo "$ESIM_LOGS" | grep -q '"result":\['; then
    echo "   ✓ Logs FOUND!"
    echo ""
    echo "   Sample log entry:"
    echo "$ESIM_LOGS" | python3 -m json.tool 2>/dev/null | head -30 || echo "$ESIM_LOGS" | head -20
else
    echo "   ? Unexpected response from Loki"
fi

echo ""
echo "7. Checking esim backend pod..."
kubectl get pods -n esim -l app=esim-backend
BACKEND_POD=$(kubectl get pod -n esim -l app=esim-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$BACKEND_POD" ]; then
    echo "   ✓ Backend pod: $BACKEND_POD"
    echo ""
    echo "   Recent backend logs (last 3 lines):"
    kubectl logs -n esim $BACKEND_POD --tail=3 | sed 's/^/   /'
else
    echo "   ✗ No backend pod found"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""

if echo "$NAMESPACES" | grep -q "esim"; then
    echo "✅ SUCCESS! Loki is collecting logs from esim namespace!"
    echo ""
    echo "You can now view logs in Grafana:"
    echo "  1. Go to Grafana Explore"
    echo "  2. Select Loki data source"
    echo "  3. Use query: {namespace=\"esim\"}"
    echo "  4. Or query: {namespace=\"esim\", app=\"esim-backend\"}"
    echo ""
    echo "Common queries:"
    echo "  All esim logs:     {namespace=\"esim\"}"
    echo "  Backend only:      {namespace=\"esim\", app=\"esim-backend\"}"
    echo "  Errors only:       {namespace=\"esim\"} |~ \"ERROR|error\""
    echo "  API requests:      {namespace=\"esim\"} |~ \"GET|POST|PUT|DELETE\""
else
    echo "⚠️  Loki is NOT yet receiving esim logs"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Generate test traffic:"
    echo "     kubectl exec -n esim $BACKEND_POD -- wget -qO- http://localhost:3000/api/esim/plans"
    echo ""
    echo "  2. Wait 30 seconds and re-run this script"
    echo ""
    echo "  3. Check Promtail is reading correct paths:"
    echo "     kubectl exec -n monitoring $PROMTAIL_POD -- cat /etc/promtail/promtail.yaml | grep __path__"
    echo ""
    echo "  4. Restart Promtail if needed:"
    echo "     kubectl delete pod -n monitoring $PROMTAIL_POD"
fi

echo ""

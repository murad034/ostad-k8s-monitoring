#!/bin/bash

# Start All Port Forwards in Background
# This script starts both Grafana and Backend port forwards

echo "=========================================="
echo "Starting All Port Forwards"
echo "=========================================="
echo ""

# Kill existing port forwards
echo "Stopping existing port forwards..."
pkill -f 'kubectl port-forward' 2>/dev/null
sleep 2

# Start Grafana port forward in background
echo "Starting Grafana port forward (port 3000)..."
nohup kubectl port-forward -n monitoring svc/grafana-simple 3000:3000 --address='0.0.0.0' > /tmp/grafana-pf.log 2>&1 &
GRAFANA_PID=$!
echo "✓ Grafana port-forward started (PID: $GRAFANA_PID)"

# Wait a moment
sleep 2

# Start Backend port forward in background
echo "Starting Backend port forward (port 3001)..."
nohup kubectl port-forward -n esim svc/esim-backend 3001:3000 --address='0.0.0.0' > /tmp/backend-pf.log 2>&1 &
BACKEND_PID=$!
echo "✓ Backend port-forward started (PID: $BACKEND_PID)"

# Wait and verify
sleep 3

echo ""
echo "Verifying port forwards..."
if lsof -i:3000 >/dev/null 2>&1; then
    echo "✓ Grafana is listening on port 3000"
else
    echo "⚠️  Grafana port forward may have failed"
    echo "Check logs: tail /tmp/grafana-pf.log"
fi

if lsof -i:3001 >/dev/null 2>&1; then
    echo "✓ Backend is listening on port 3001"
else
    echo "⚠️  Backend port forward may have failed"
    echo "Check logs: tail /tmp/backend-pf.log"
fi

echo ""
echo "=========================================="
echo "Access URLs:"
echo "=========================================="
echo ""
echo "Grafana: http://$(curl -s ifconfig.me):3000"
echo "Backend: http://$(curl -s ifconfig.me):3001"
echo ""
echo "Login: admin / admin"
echo ""
echo "=========================================="
echo "Management Commands:"
echo "=========================================="
echo ""
echo "View Grafana logs:  tail -f /tmp/grafana-pf.log"
echo "View Backend logs:  tail -f /tmp/backend-pf.log"
echo "Stop all forwards:  pkill -f 'kubectl port-forward'"
echo "Restart forwards:   ./scripts/start-port-forwards.sh"
echo ""
echo "Process IDs:"
echo "  Grafana: $GRAFANA_PID"
echo "  Backend: $BACKEND_PID"
echo ""

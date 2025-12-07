#!/bin/bash

# Stable Port Forward with Auto-Restart
# This script keeps port-forward running and auto-restarts on failure

SERVICE=$1
NAMESPACE=$2
LOCAL_PORT=$3
TARGET_PORT=$4

if [ -z "$SERVICE" ] || [ -z "$NAMESPACE" ] || [ -z "$LOCAL_PORT" ] || [ -z "$TARGET_PORT" ]; then
    echo "Usage: ./stable-port-forward.sh <service> <namespace> <local-port> <target-port>"
    echo ""
    echo "Examples:"
    echo "  ./stable-port-forward.sh grafana-simple monitoring 3000 3000"
    echo "  ./stable-port-forward.sh esim-backend esim 3001 3000"
    exit 1
fi

echo "Starting stable port-forward for $SERVICE in namespace $NAMESPACE"
echo "Forwarding 0.0.0.0:$LOCAL_PORT -> $TARGET_PORT"
echo "Press Ctrl+C to stop"
echo ""

# Function to kill existing port-forward on the same port
cleanup() {
    echo "Cleaning up..."
    lsof -ti:$LOCAL_PORT | xargs kill -9 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# Loop to restart port-forward on failure
while true; do
    echo "[$(date)] Starting port-forward..."
    
    kubectl port-forward -n $NAMESPACE svc/$SERVICE $LOCAL_PORT:$TARGET_PORT --address='0.0.0.0'
    
    EXIT_CODE=$?
    echo "[$(date)] Port-forward exited with code $EXIT_CODE"
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "Port-forward stopped cleanly"
        break
    else
        echo "Port-forward failed. Restarting in 3 seconds..."
        sleep 3
    fi
done

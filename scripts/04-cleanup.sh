#!/bin/bash

##############################################################################
# Cleanup Script
# Description: Removes all deployed components
# Author: OSTAD 2025 - Module 7
##############################################################################

echo "============================================"
echo "Cleanup: Removing all components"
echo "============================================"

read -p "Are you sure you want to delete all components? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Removing Grafana dashboards..."
kubectl delete -f ../manifests/grafana/ --ignore-not-found=true

echo ""
echo "Removing Loki and Promtail..."
kubectl delete -f ../manifests/loki/ --ignore-not-found=true

echo ""
echo "Uninstalling Prometheus stack..."
helm uninstall prometheus -n monitoring --ignore-not-found

echo ""
echo "Removing application..."
kubectl delete -f ../manifests/application/ --ignore-not-found=true

echo ""
echo "Removing namespaces..."
kubectl delete -f ../manifests/namespace/ --ignore-not-found=true

echo ""
echo "Waiting for resources to be deleted..."
sleep 10

echo ""
echo "============================================"
echo "Cleanup Complete!"
echo "============================================"
echo ""
echo "To delete the Minikube cluster:"
echo "  minikube delete"
echo ""

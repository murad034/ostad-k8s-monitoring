#!/bin/bash

##############################################################################
# Verification Script
# Description: Verifies the entire monitoring stack is working correctly
# Author: OSTAD 2025 - Module 7
##############################################################################

echo "============================================"
echo "Kubernetes Monitoring Stack Verification"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

# Function to check status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAILED++))
    fi
}

# Function to check pod status
check_pod() {
    local namespace=$1
    local label=$2
    local name=$3
    
    echo -n "Checking $name... "
    kubectl get pods -n $namespace -l $label 2>/dev/null | grep -q "Running"
    check_status
}

echo "SECTION 1: Cluster Health"
echo "-------------------------"

echo -n "1.1 Minikube cluster running... "
minikube status | grep -q "Running"
check_status

echo -n "1.2 Kubectl connectivity... "
kubectl cluster-info > /dev/null 2>&1
check_status

echo -n "1.3 Nodes ready... "
kubectl get nodes | grep -q "Ready"
check_status

echo ""
echo "SECTION 2: Namespaces"
echo "-------------------------"

echo -n "2.1 Application namespace exists... "
kubectl get namespace application > /dev/null 2>&1
check_status

echo -n "2.2 Monitoring namespace exists... "
kubectl get namespace monitoring > /dev/null 2>&1
check_status

echo ""
echo "SECTION 3: Application Deployment"
echo "-------------------------"

echo -n "3.1 Nginx deployment exists... "
kubectl get deployment nginx-deployment -n application > /dev/null 2>&1
check_status

echo -n "3.2 Nginx pods running... "
kubectl get pods -n application -l app=nginx 2>/dev/null | grep -q "Running"
check_status

echo -n "3.3 Nginx service exists... "
kubectl get svc nginx-service -n application > /dev/null 2>&1
check_status

NGINX_PODS=$(kubectl get pods -n application -l app=nginx --no-headers 2>/dev/null | wc -l)
echo "3.4 Number of Nginx pods: $NGINX_PODS (expected: 3)"

echo ""
echo "SECTION 4: Prometheus Stack"
echo "-------------------------"

echo -n "4.1 Prometheus operator running... "
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-operator 2>/dev/null | grep -q "Running"
check_status

echo -n "4.2 Prometheus server running... "
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus 2>/dev/null | grep -q "Running"
check_status

echo -n "4.3 Alertmanager running... "
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager 2>/dev/null | grep -q "Running"
check_status

echo -n "4.4 Node exporter running... "
kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter 2>/dev/null | grep -q "Running"
check_status

echo -n "4.5 Kube-state-metrics running... "
kubectl get pods -n monitoring -l app.kubernetes.io/name=kube-state-metrics 2>/dev/null | grep -q "Running"
check_status

echo ""
echo "SECTION 5: Grafana"
echo "-------------------------"

echo -n "5.1 Grafana pod running... "
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana 2>/dev/null | grep -q "Running"
check_status

echo -n "5.2 Grafana service exists... "
kubectl get svc -n monitoring prometheus-grafana > /dev/null 2>&1
check_status

echo -n "5.3 Grafana secret exists... "
kubectl get secret -n monitoring prometheus-grafana > /dev/null 2>&1
check_status

echo "5.4 Grafana password:"
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 --decode 2>/dev/null
echo ""

echo ""
echo "SECTION 6: Loki"
echo "-------------------------"

echo -n "6.1 Loki pod running... "
kubectl get pods -n monitoring -l app=loki 2>/dev/null | grep -q "Running"
check_status

echo -n "6.2 Loki service exists... "
kubectl get svc -n monitoring loki > /dev/null 2>&1
check_status

echo -n "6.3 Loki ConfigMap exists... "
kubectl get cm -n monitoring loki-config > /dev/null 2>&1
check_status

echo ""
echo "SECTION 7: Promtail"
echo "-------------------------"

echo -n "7.1 Promtail DaemonSet exists... "
kubectl get daemonset -n monitoring promtail > /dev/null 2>&1
check_status

echo -n "7.2 Promtail pods running... "
kubectl get pods -n monitoring -l app=promtail 2>/dev/null | grep -q "Running"
check_status

echo -n "7.3 Promtail ConfigMap exists... "
kubectl get cm -n monitoring promtail-config > /dev/null 2>&1
check_status

PROMTAIL_PODS=$(kubectl get pods -n monitoring -l app=promtail --no-headers 2>/dev/null | wc -l)
echo "7.4 Number of Promtail pods: $PROMTAIL_PODS"

echo ""
echo "SECTION 8: Resources"
echo "-------------------------"

echo "8.1 Node Resources:"
kubectl top nodes 2>/dev/null || echo "  Metrics server not ready or not available"

echo ""
echo "8.2 Pod Resources (Top 5 CPU):"
kubectl top pods -A 2>/dev/null | head -n 6 || echo "  Metrics server not ready or not available"

echo ""
echo "SECTION 9: Services"
echo "-------------------------"

echo "9.1 All Services in Monitoring Namespace:"
kubectl get svc -n monitoring

echo ""
echo "9.2 All Services in Application Namespace:"
kubectl get svc -n application

echo ""
echo "SECTION 10: Connectivity Tests"
echo "-------------------------"

echo -n "10.1 Prometheus service accessible... "
kubectl run test-prom --rm -it --restart=Never --image=curlimages/curl -- \
    curl -s http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/targets \
    > /dev/null 2>&1
check_status

echo -n "10.2 Grafana service accessible... "
kubectl run test-grafana --rm -it --restart=Never --image=curlimages/curl -- \
    curl -s http://prometheus-grafana.monitoring.svc.cluster.local > /dev/null 2>&1
check_status

echo -n "10.3 Loki service accessible... "
kubectl run test-loki --rm -it --restart=Never --image=curlimages/curl -- \
    curl -s http://loki.monitoring.svc.cluster.local:3100/ready > /dev/null 2>&1
check_status

echo ""
echo "SECTION 11: Recent Events"
echo "-------------------------"

echo "11.1 Warning events in last 5 minutes:"
kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp' 2>/dev/null | tail -n 10

echo ""
echo "============================================"
echo "Verification Summary"
echo "============================================"
echo ""
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Your monitoring stack is ready.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Port forward Grafana:"
    echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'"
    echo ""
    echo "2. Access Grafana at: http://<EC2-PUBLIC-IP>:3000"
    echo "   Username: admin"
    echo "   Password: (shown above in section 5.4)"
    echo ""
    echo "3. Add Loki data source in Grafana:"
    echo "   URL: http://loki.monitoring.svc.cluster.local:3100"
    echo ""
    echo "4. Take screenshots for your report!"
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please review the output above.${NC}"
    echo ""
    echo "Troubleshooting tips:"
    echo "1. Check pod logs: kubectl logs <pod-name> -n <namespace>"
    echo "2. Describe failing pods: kubectl describe pod <pod-name> -n <namespace>"
    echo "3. Check events: kubectl get events -n <namespace> --sort-by='.lastTimestamp'"
    echo "4. Review docs/TROUBLESHOOTING.md for common issues"
    exit 1
fi

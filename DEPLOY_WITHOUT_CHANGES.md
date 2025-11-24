# Deploy Your Live Backend to Kubernetes - NO CODE CHANGES

This guide deploys your **existing live backend** to Kubernetes and monitors it with Grafana/Prometheus/Loki **WITHOUT modifying any backend code**.

## What You'll Get (Without Touching Backend Code)

✅ **From Kubernetes:**
- Pod CPU usage
- Pod Memory usage
- Pod restart count
- Pod status (running/failed)
- Network traffic

✅ **From Prometheus:**
- HTTP request count (via Kubernetes metrics)
- Response times (via Ingress/Service)
- Container metrics
- Resource utilization

✅ **From Loki:**
- All application logs
- stdout/stderr from your containers
- Error logs
- Request logs (if your app logs them)

## ❌ What You WON'T Get (Without Backend Changes)

- Custom business metrics (e.g., "eSIM activations count")
- Detailed error tracking by type
- Database query performance
- Custom application metrics

## Step-by-Step: Deploy Without Backend Changes

### Step 1: Use Your Current Live Code

**NO CHANGES NEEDED!** Your current backend works as-is.

### Step 2: Build Docker Image (Current Code)

```bash
cd E:\Development\Server\laragon\www\esim\esim-backend

# Build with your existing code (NO modifications)
docker build -t YOUR_DOCKERHUB_USERNAME/esim-backend:latest .

# Push to Docker Hub
docker login
docker push YOUR_DOCKERHUB_USERNAME/esim-backend:latest
```

### Step 3: Deploy to Kubernetes

```bash
# On your EC2 instance
kubectl apply -f manifests/application/esim-backend-no-changes.yaml

# Check deployment
kubectl get pods -n esim
kubectl get svc -n esim
```

### Step 4: Access Your Backend

```bash
# Port forward
kubectl port-forward -n esim svc/esim-backend 3001:3000 --address='0.0.0.0'

# Your backend is now accessible at:
# http://3.238.231.12:3001
```

### Step 5: View Metrics in Grafana (Already Works!)

```bash
# Port forward Grafana (already deployed)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'

# Open: http://3.238.231.12:3000
```

**Available Metrics (No Backend Changes):**

```promql
# CPU Usage
sum(rate(container_cpu_usage_seconds_total{namespace="esim", pod=~"esim-backend.*"}[5m])) by (pod)

# Memory Usage
sum(container_memory_working_set_bytes{namespace="esim", pod=~"esim-backend.*"}) by (pod)

# Pod Status
kube_pod_status_phase{namespace="esim", pod=~"esim-backend.*"}

# Restart Count
kube_pod_container_status_restarts_total{namespace="esim", pod=~"esim-backend.*"}

# Network Received
rate(container_network_receive_bytes_total{namespace="esim"}[5m])

# Network Transmitted
rate(container_network_transmit_bytes_total{namespace="esim"}[5m])
```

### Step 6: View Logs in Loki (Already Works!)

In Grafana → Explore → Loki:

```logql
# All logs from your backend
{namespace="esim", app="esim-backend"}

# Error logs only
{namespace="esim", app="esim-backend"} |~ "error|Error|ERROR"

# Logs from last 5 minutes
{namespace="esim", app="esim-backend"} [5m]
```

## What's Monitored Automatically

| Metric | Source | Requires Backend Changes? |
|--------|--------|---------------------------|
| CPU Usage | Kubernetes | ❌ No |
| Memory Usage | Kubernetes | ❌ No |
| Pod Restarts | Kubernetes | ❌ No |
| Network I/O | Kubernetes | ❌ No |
| Application Logs | Loki | ❌ No |
| HTTP Request Count | Service Mesh* | ❌ No |
| Container Status | Kubernetes | ❌ No |
| eSIM Activations | Application | ✅ **Yes** |
| Custom Errors | Application | ✅ **Yes** |
| DB Query Time | Application | ✅ **Yes** |

*Requires service mesh like Istio (optional)

## Decision: Do You Need Backend Changes?

### Choose NO if:
- ✅ You just want infrastructure monitoring
- ✅ You don't want to risk your live code
- ✅ Basic metrics (CPU, memory, logs) are enough
- ✅ You want quick deployment

### Choose YES if:
- ✅ You need business metrics (activations, transactions)
- ✅ You want detailed error tracking
- ✅ You need to track custom operations
- ✅ You want database performance metrics

## Recommendation for Live Production

**Phase 1: Deploy WITHOUT Changes** (This guide)
- Deploy your current backend as-is
- Monitor with Kubernetes metrics
- Collect logs with Loki
- **Zero risk to production**

**Phase 2: Add Metrics Later** (Optional)
- Test metrics integration in development first
- Add `/metrics` endpoint when ready
- Deploy updated version gradually
- No downtime required

## Next Steps

1. **Right now:** Deploy with `esim-backend-no-changes.yaml`
2. **Monitor:** Use Grafana to see CPU, memory, logs
3. **Later (optional):** Add custom metrics when you're ready

## Files to Use

- `manifests/application/esim-backend-no-changes.yaml` - Use this (no code changes)
- `manifests/application/esim-backend-deployment.yaml` - Use later (with metrics)

Your live backend stays untouched, and you still get monitoring! 🎉

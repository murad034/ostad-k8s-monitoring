# eSIM Backend Integration with Kubernetes Monitoring

This guide shows how to integrate your eSIM backend with Grafana, Prometheus, and Loki.

## What Was Created

### In Your eSIM Backend Project (`E:\Development\Server\laragon\www\esim\esim-backend\`) - NestJS

1. **`src/metrics/metrics.service.ts`** - Prometheus metrics service
   - HTTP request tracking
   - eSIM activation counters
   - Error tracking
   - Database query monitoring

2. **`src/metrics/metrics.controller.ts`** - Health & metrics endpoints
   - `/metrics` - Prometheus metrics
   - `/health` - Health check
   - `/ready` - Readiness check

3. **`src/metrics/metrics.module.ts`** - Global metrics module

4. **`src/metrics/metrics.middleware.ts`** - Automatic request tracking

5. **`UPDATE_APP_MODULE.md`** - Simple instructions to add to your `app.module.ts`
   - Only need to import MetricsModule
   - No changes to existing code needed

### In Monitoring Project (`E:\Development\Server\laragon\www\devops\ostad-2025\ostad-k8s-monitoring\`)

1. **`manifests/application/esim-backend-deployment.yaml`** - Kubernetes deployment
   - Namespace, Deployment, Service, ConfigMap
   - Health/readiness probes
   - Prometheus annotations

2. **`manifests/prometheus/esim-servicemonitor.yaml`** - Prometheus scraping
   - Tells Prometheus to collect metrics from eSIM backend

3. **`manifests/loki/esim-promtail-config.yaml`** - Log collection
   - Configures Loki to collect eSIM logs

4. **`scripts/deploy-esim.sh`** - Deployment script
   - Automated deployment to Kubernetes

## Step-by-Step Setup

### Step 1: Update Your NestJS Backend

1. Install dependencies:
```bash
cd E:\Development\Server\laragon\www\esim\esim-backend
npm install prom-client
```

2. **Metrics module is already created!** 
   - All files are in `src/metrics/` folder
   - Just follow `UPDATE_APP_MODULE.md` to add 3 lines to your `app.module.ts`
   - **No changes to existing code required!**
   - Your existing controllers and services work as-is

3. Update your `src/app.module.ts`:
   - Add `import { MetricsModule } from './metrics/metrics.module';`
   - Add `import { MetricsMiddleware } from './metrics/metrics.middleware';`
   - Add `MetricsModule` to imports array
   - Implement `NestModule` interface (see UPDATE_APP_MODULE.md)

4. Test locally:
```bash
npm run start:dev
# Visit http://localhost:3000/metrics
# Visit http://localhost:3000/health
# Visit http://localhost:3000/ready
```

### Step 2: Build and Push Docker Image

```bash
# In your eSIM backend directory
cd E:\Development\Server\laragon\www\esim\esim-backend

# Build the image (replace YOUR_DOCKERHUB_USERNAME)
docker build -t YOUR_DOCKERHUB_USERNAME/esim-backend:latest .

# Login to Docker Hub
docker login

# Push the image
docker push YOUR_DOCKERHUB_USERNAME/esim-backend:latest
```

### Step 3: Update Kubernetes Manifest

Edit `manifests/application/esim-backend-deployment.yaml` and replace `YOUR_DOCKERHUB_USERNAME` with your actual Docker Hub username.

### Step 4: Deploy to Kubernetes

On your EC2 instance:

```bash
# Copy the monitoring project to EC2
scp -i "your-key.pem" -r E:\Development\Server\laragon\www\devops\ostad-2025\ostad-k8s-monitoring ubuntu@3.238.231.12:~/

# SSH to EC2
ssh -i "your-key.pem" ubuntu@3.238.231.12

# Navigate to project
cd ~/ostad-k8s-monitoring

# Run deployment script
chmod +x scripts/deploy-esim.sh
./scripts/deploy-esim.sh
```

Or deploy manually:

```bash
# Deploy eSIM backend
kubectl apply -f manifests/application/esim-backend-deployment.yaml

# Deploy Prometheus ServiceMonitor
kubectl apply -f manifests/prometheus/esim-servicemonitor.yaml

# Configure Loki logging
kubectl apply -f manifests/loki/esim-promtail-config.yaml

# Verify
kubectl get pods -n esim
kubectl get svc -n esim
```

### Step 5: Port Forward and Access

```bash
# Forward eSIM backend
kubectl port-forward -n esim svc/esim-backend 3001:3000 --address='0.0.0.0'

# Access:
# API: http://3.238.231.12:3001
# Health: http://3.238.231.12:3001/health
# Metrics: http://3.238.231.12:3001/metrics
```

### Step 6: Verify Prometheus is Scraping

```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 --address='0.0.0.0'

# Open in browser: http://3.238.231.12:9090
# Go to Status → Targets
# Look for "esim-backend-monitor" - should be UP
```

### Step 7: View Metrics in Grafana

```bash
# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'

# Open: http://3.238.231.12:3000
# Login: admin / <password from kubectl get secret>
```

Create a dashboard with these queries:

**HTTP Requests per Second:**
```promql
rate(esim_http_requests_total[5m])
```

**Request Duration (95th percentile):**
```promql
histogram_quantile(0.95, rate(esim_http_request_duration_seconds_bucket[5m]))
```

**eSIM Activations:**
```promql
rate(esim_activations_total[5m])
```

**Error Rate:**
```promql
rate(esim_errors_total[5m])
```

**Active Connections:**
```promql
esim_active_connections
```

### Step 8: View Logs in Grafana

1. In Grafana, go to **Explore**
2. Select **Loki** data source
3. Use this query:
```logql
{namespace="esim", app="esim-backend"}
```

Filter errors:
```logql
{namespace="esim", app="esim-backend"} |= "error"
```

## Environment Variables

Add your environment variables to the ConfigMap or create a Secret:

```yaml
# For sensitive data, create a secret:
apiVersion: v1
kind: Secret
metadata:
  name: esim-backend-secrets
  namespace: esim
type: Opaque
stringData:
  DATABASE_URL: "your-database-url"
  JWT_SECRET: "your-jwt-secret"
  API_KEY: "your-api-key"
```

Apply:
```bash
kubectl apply -f esim-secrets.yaml
```

## Troubleshooting

**Pods not starting:**
```bash
kubectl describe pod -n esim <pod-name>
kubectl logs -n esim <pod-name>
```

**Prometheus not scraping:**
```bash
# Check ServiceMonitor
kubectl get servicemonitor -n monitoring esim-backend-monitor -o yaml

# Check if pod has annotations
kubectl get pod -n esim -l app=esim-backend -o yaml | grep -A3 annotations
```

**Metrics endpoint not accessible:**
```bash
# Test from inside the pod
POD_NAME=$(kubectl get pods -n esim -l app=esim-backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n esim $POD_NAME -- wget -qO- http://localhost:3000/metrics
```

**No logs in Loki:**
```bash
# Check Promtail logs
kubectl logs -n monitoring -l app=promtail

# Verify Promtail config
kubectl get configmap -n monitoring promtail-esim-config -o yaml
```

## Metrics Available

After setup, you'll have these metrics in Prometheus:

- `esim_http_request_duration_seconds` - Request duration
- `esim_http_requests_total` - Total requests
- `esim_active_connections` - Active connections
- `esim_activations_total` - eSIM activations
- `esim_errors_total` - Errors
- `esim_db_query_duration_seconds` - Database query time
- `esim_backend_process_cpu_user_seconds_total` - CPU usage
- `esim_backend_process_resident_memory_bytes` - Memory usage
- `esim_backend_nodejs_eventloop_lag_seconds` - Event loop lag

## Next Steps

1. Create custom Grafana dashboards for eSIM metrics
2. Set up alerts in Prometheus
3. Add more custom metrics for business KPIs
4. Configure log retention policies in Loki
5. Add frontend monitoring (if you have a frontend)

## Files Reference

| File | Location | Purpose |
|------|----------|---------|
| `metrics.service.ts` | eSIM backend/src/metrics | Prometheus metrics service |
| `metrics.controller.ts` | eSIM backend/src/metrics | Health & metrics endpoints |
| `metrics.module.ts` | eSIM backend/src/metrics | NestJS module |
| `metrics.middleware.ts` | eSIM backend/src/metrics | Request tracking |
| `UPDATE_APP_MODULE.md` | eSIM backend | Quick integration guide |
| `NESTJS_INTEGRATION.md` | eSIM backend | Complete documentation |
| `Dockerfile` | eSIM backend | Container image |
| `esim-backend-deployment.yaml` | Monitoring project | K8s deployment |
| `esim-servicemonitor.yaml` | Monitoring project | Prometheus config |
| `esim-promtail-config.yaml` | Monitoring project | Loki config |
| `deploy-esim.sh` | Monitoring project | Deployment script |

## Support

For issues, check:
- Pod logs: `kubectl logs -n esim <pod-name>`
- Events: `kubectl get events -n esim`
- Prometheus targets: http://3.238.231.12:9090/targets
- Grafana Explore: http://3.238.231.12:3000/explore

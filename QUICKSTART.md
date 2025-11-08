# Quick Start Guide

Get up and running with the Kubernetes Monitoring & Logging Dashboard in under 30 minutes!

## Prerequisites

- AWS account with EC2 access
- SSH key pair for EC2
- Basic command line knowledge

## Quick Setup (30 Minutes)

### Step 1: Launch EC2 Instance (5 minutes)

1. **AWS Console** → **EC2** → **Launch Instance**

2. **Configuration**:

   - Name: `k8s-monitoring-cluster`
   - AMI: Ubuntu 22.04 LTS
   - Instance Type: `t3.medium`
   - Key Pair: Select/Create your key
   - Storage: 30 GB gp3

3. **Security Group** - Add these inbound rules:

   ```
   SSH         22          Your IP
   Custom TCP  3000        Your IP  (Grafana)
   Custom TCP  9090        Your IP  (Prometheus)
   Custom TCP  30000-32767 Your IP  (NodePorts)
   ```

4. **Launch** and wait for instance to be running

5. **Note down the Public IP address**

### Step 2: Connect and Setup (10 minutes)

```bash
# 1. SSH to instance
ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>

# 2. Clone/Download project files
# Option A: If using Git
git clone <your-repo-url>
cd k8-monitoring

# Option B: Create files manually (copy files to EC2)
mkdir -p k8-monitoring
cd k8-monitoring
# Transfer files using scp or upload to S3 and download

# 3. Make scripts executable
chmod +x scripts/*.sh

# 4. Run EC2 setup script
./scripts/01-ec2-setup.sh

# 5. IMPORTANT: Apply Docker group changes
newgrp docker

# 6. Install Minikube
./scripts/02-install-minikube.sh
```

### Step 3: Deploy Everything (10 minutes)

```bash
# Deploy all components at once
./scripts/03-deploy-all.sh

# This script will:
# - Create namespaces
# - Deploy Nginx application
# - Install Prometheus and Grafana
# - Deploy Loki and Promtail
# - Configure dashboards

# Wait for all pods to be ready (this may take 5-10 minutes)
watch kubectl get pods -A
# Press Ctrl+C when all pods show Running status
```

### Step 4: Access Services (5 minutes)

#### 4.1 Get Grafana Password

```bash
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

**Save this password!**

#### 4.2 Start Port Forwarding

**Option 1: Foreground (for testing)**

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'
```

**Option 2: Background (recommended)**

```bash
# Grafana
nohup kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0' > /tmp/grafana.log 2>&1 &

# Prometheus (optional)
nohup kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 --address='0.0.0.0' > /tmp/prometheus.log 2>&1 &
```

#### 4.3 Access Grafana

1. Open browser: `http://<EC2-PUBLIC-IP>:3000`
2. Login:
   - Username: `admin`
   - Password: (from step 4.1)
3. Click **Dashboards** → **Browse**
4. You should see pre-loaded dashboards

### Step 5: Add Loki Data Source

1. In Grafana: **Configuration** (⚙️) → **Data Sources**
2. Click **Add data source**
3. Select **Loki**
4. Set URL: `http://loki.monitoring.svc.cluster.local:3100`
5. Click **Save & Test**
6. You should see "Data source connected and labels found"

### Step 6: Import Custom Dashboards

#### Import Metrics Dashboard

1. **Dashboards** → **Import**
2. Upload `dashboards/k8s-cluster-metrics.json`
3. Select **Prometheus** as data source
4. Click **Import**

#### Import Logs Dashboard

1. **Dashboards** → **Import**
2. Upload `dashboards/application-logs.json`
3. Select **Loki** as data source
4. Click **Import**

## Verification Checklist

✅ **Cluster**

```bash
kubectl get nodes
# Should show 1 node in Ready state
```

✅ **Namespaces**

```bash
kubectl get ns
# Should show: application, monitoring
```

✅ **Application**

```bash
kubectl get pods -n application
# Should show 3 nginx pods Running
```

✅ **Monitoring Stack**

```bash
kubectl get pods -n monitoring
# All pods should be Running
```

✅ **Grafana**

- Can access http://<EC2-IP>:3000
- Can login successfully
- Dashboards visible

✅ **Metrics**

- Open metrics dashboard
- See data in CPU/Memory panels
- Graphs showing trends

✅ **Logs**

- Open logs dashboard
- See application logs streaming
- Can filter by log level

## Quick Commands Reference

### Cluster Management

```bash
# Status
minikube status

# Stop
minikube stop

# Start
minikube start

# Delete
minikube delete
```

### View Resources

```bash
# All pods
kubectl get pods -A

# Application pods
kubectl get pods -n application

# Monitoring pods
kubectl get pods -n monitoring

# Services
kubectl get svc -A
```

### Port Forwarding

```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 --address='0.0.0.0'

# Application
kubectl port-forward -n application svc/nginx-service 8080:80 --address='0.0.0.0'
```

### Check Logs

```bash
# Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Prometheus logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Loki logs
kubectl logs -n monitoring -l app=loki

# Promtail logs
kubectl logs -n monitoring -l app=promtail

# Application logs
kubectl logs -n application -l app=nginx
```

### Troubleshooting

```bash
# Pod not starting
kubectl describe pod <pod-name> -n <namespace>

# Recent events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Resource usage
kubectl top nodes
kubectl top pods -A

# Restart deployment
kubectl rollout restart deployment <deployment-name> -n <namespace>
```

## What to Monitor

Once everything is running, monitor these metrics:

### Cluster Health

- ✅ All nodes in Ready state
- ✅ CPU usage < 80%
- ✅ Memory usage < 80%
- ✅ Disk space available

### Application Health

- ✅ All pods Running
- ✅ No excessive restarts
- ✅ Response times acceptable
- ✅ No error logs

### Monitoring Stack Health

- ✅ Prometheus scraping targets
- ✅ Grafana accessible
- ✅ Loki receiving logs
- ✅ Dashboards showing data

## Taking Screenshots for Report

Follow this sequence for comprehensive documentation:

```bash
# 1. EC2 Console
# Screenshot: Instance running

# 2. Minikube status
minikube status
# Screenshot: Terminal output

# 3. All pods
kubectl get pods -A
# Screenshot: All pods Running

# 4. Application
kubectl get all -n application
# Screenshot: Application resources

# 5. Access Grafana
# Screenshot: Login page
# Screenshot: Main dashboard
# Screenshot: Metrics dashboard with data
# Screenshot: Logs dashboard with data

# 6. Prometheus
# Screenshot: Prometheus targets page
```

## Cleanup

When you're done:

```bash
# Delete all resources
./scripts/04-cleanup.sh

# Or delete just the cluster
minikube delete

# Don't forget to stop/terminate EC2 instance!
```

## Next Steps

1. ✅ Explore pre-loaded dashboards
2. ✅ Create custom queries in Grafana Explore
3. ✅ Test log filtering with LogQL
4. ✅ Simulate load and watch metrics change
5. ✅ Complete your assignment report

## Common Issues

### Can't Access Grafana

```bash
# Check pod status
kubectl get pods -n monitoring | grep grafana

# Check port forward is running
ps aux | grep port-forward

# Restart port forward
pkill -f "port-forward.*grafana"
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'
```

### No Data in Dashboards

```bash
# Check Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 --address='0.0.0.0'
# Visit http://<EC2-IP>:9090 and verify targets are up

# Check time range in Grafana (try "Last 6 hours")
```

### Loki Not Showing Logs

```bash
# Check Loki is running
kubectl get pods -n monitoring | grep loki

# Check Promtail logs
kubectl logs -n monitoring -l app=promtail

# Verify data source URL in Grafana
# Should be: http://loki.monitoring.svc.cluster.local:3100
```

## Getting Help

- 📖 See `docs/TROUBLESHOOTING.md` for detailed solutions
- 📝 Check logs: `kubectl logs <pod-name> -n <namespace>`
- 🔍 Describe resources: `kubectl describe pod <pod-name> -n <namespace>`
- 📚 Official docs: Kubernetes, Prometheus, Grafana, Loki

---

**Time Budget:**

- EC2 Setup: 5 min
- System Setup: 10 min
- Deployment: 10 min
- Access & Verify: 5 min
- **Total: ~30 minutes**

**Good luck! 🚀**

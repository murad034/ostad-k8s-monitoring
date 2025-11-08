# Kubernetes Monitoring & Logging Dashboard

A comprehensive monitoring and logging solution for Kubernetes using Prometheus, Grafana, and Loki on Minikube (AWS EC2).

## Project Structure

```
k8-monitoring/
├── scripts/                    # Setup and deployment scripts
│   ├── 01-ec2-setup.sh        # EC2 instance initial setup
│   ├── 02-install-minikube.sh # Minikube installation
│   ├── 03-deploy-all.sh       # Deploy all components
│   └── 04-cleanup.sh          # Cleanup script
├── manifests/                  # Kubernetes manifests
│   ├── namespace/             # Namespace definitions
│   ├── application/           # Sample application
│   ├── prometheus/            # Prometheus monitoring
│   ├── loki/                  # Loki logging
│   └── grafana/               # Grafana dashboards
├── dashboards/                 # Grafana dashboard JSONs
│   ├── k8s-cluster-metrics.json
│   └── application-logs.json
├── docs/                       # Documentation
│   ├── screenshots/           # Screenshots folder
│   └── report-template.md     # Report template
└── README.md                   # This file
```

## Prerequisites

- AWS Account with EC2 access
- Basic knowledge of Kubernetes, Docker, and Linux
- SSH client

## Step-by-Step Implementation

### Phase 1: EC2 Instance Setup

#### 1.1 Launch EC2 Instance

1. **Log in to AWS Console**

   - Navigate to EC2 Dashboard

2. **Launch Instance with these specifications:**

   - **AMI**: Ubuntu 22.04 LTS (64-bit x86)
   - **Instance Type**: t3.medium (2 vCPU, 4 GB RAM minimum)
     - _Recommended_: t3.large (2 vCPU, 8 GB RAM) for better performance
   - **Storage**: 30 GB gp3
   - **Security Group**: Create with these inbound rules:
     ```
     SSH (22)         - Your IP
     HTTP (80)        - Your IP
     HTTPS (443)      - Your IP
     Custom TCP 3000  - Your IP (Grafana)
     Custom TCP 9090  - Your IP (Prometheus)
     Custom TCP 30000-32767 - Your IP (NodePort range)
     ```
   - **Key Pair**: Create/select your key pair

3. **Take Screenshot**: EC2 instance running in AWS Console

4. **Connect to EC2**:
   ```bash
   ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>
   ```

#### 1.2 Setup EC2 Environment

Run the setup script:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Run the setup script
chmod +x scripts/01-ec2-setup.sh
./scripts/01-ec2-setup.sh
```

This script installs:

- Docker
- kubectl
- Helm
- Required dependencies

### Phase 2: Minikube Cluster Setup

#### 2.1 Install Minikube

```bash
chmod +x scripts/02-install-minikube.sh
./scripts/02-install-minikube.sh
```

#### 2.2 Verify Cluster

```bash
# Check cluster status
minikube status

# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -A
```

**Take Screenshot**: Minikube cluster running (`minikube status` output)

### Phase 3: Deploy Sample Application

```bash
# Create application namespace
kubectl apply -f manifests/namespace/

# Deploy nginx application
kubectl apply -f manifests/application/

# Verify deployment
kubectl get all -n application
```

**Take Screenshot**: Application pods running

### Phase 4: Deploy Prometheus & Grafana

#### 4.1 Add Helm Repositories

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

#### 4.2 Install kube-prometheus-stack

```bash
# Install with custom values
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace \
  -f manifests/prometheus/values.yaml
```

#### 4.3 Access Grafana

```bash
# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'
```

Access: `http://<EC2-PUBLIC-IP>:3000`

- Username: `admin`
- Password: (from command above)

**Take Screenshot**: Grafana login page

### Phase 5: Deploy Loki & Promtail

```bash
# Add Grafana Helm repo
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki
kubectl apply -f manifests/loki/

# Install Promtail
kubectl apply -f manifests/loki/promtail.yaml

# Verify
kubectl get pods -n monitoring | grep -E 'loki|promtail'
```

### Phase 6: Configure Grafana Dashboards

#### 6.1 Add Loki Data Source

1. In Grafana UI: **Configuration** → **Data Sources** → **Add data source**
2. Select **Loki**
3. URL: `http://loki.monitoring.svc.cluster.local:3100`
4. Click **Save & Test**

**Take Screenshot**: Loki data source configured

#### 6.2 Import Dashboards

**Option 1: Via UI**

1. **Dashboards** → **Import**
2. Upload `dashboards/k8s-cluster-metrics.json`
3. Select Prometheus data source
4. Click **Import**

Repeat for `dashboards/application-logs.json`

**Option 2: Via kubectl**

```bash
kubectl apply -f manifests/grafana/
```

**Take Screenshots**:

- Cluster metrics dashboard showing CPU/Memory usage
- Application logs dashboard with log panels

### Phase 7: Monitoring Dashboard Panels

Your Grafana dashboard should display:

1. **Cluster Overview**

   - Total Nodes
   - Total Pods
   - CPU Usage %
   - Memory Usage %

2. **Node Metrics**

   - CPU usage per node
   - Memory usage per node
   - Disk I/O
   - Network traffic

3. **Pod Metrics**

   - Pod status (Running/Pending/Failed)
   - CPU usage by pod
   - Memory usage by pod
   - Restart count

4. **Resource Trends**

   - CPU usage over time (line graph)
   - Memory usage over time (line graph)
   - Pod count over time

5. **Application Logs** (Loki)
   - Real-time log stream
   - Log levels (info, warn, error)
   - Filtered by namespace/pod

## Quick Deployment

Deploy everything at once:

```bash
chmod +x scripts/03-deploy-all.sh
./scripts/03-deploy-all.sh
```

## Access Services

```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 --address='0.0.0.0'

# Application
kubectl port-forward -n application svc/nginx-service 8080:80 --address='0.0.0.0'
```

## Useful Commands

```bash
# Check all pods
kubectl get pods -A

# Check services
kubectl get svc -A

# View logs
kubectl logs -n monitoring <pod-name>

# Describe pod
kubectl describe pod -n monitoring <pod-name>

# Get events
kubectl get events -n application --sort-by='.lastTimestamp'
```

## Cleanup

```bash
chmod +x scripts/04-cleanup.sh
./scripts/04-cleanup.sh
```

Or manual cleanup:

```bash
# Delete namespaces
kubectl delete namespace application monitoring

# Delete Minikube cluster
minikube delete
```

## Troubleshooting

### Common Issues

**1. Minikube won't start**

```bash
minikube delete
minikube start --driver=docker --memory=4096 --cpus=2
```

**2. Pods stuck in Pending**

```bash
# Check events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes
```

**3. Grafana can't connect to Prometheus**

- Verify Prometheus is running: `kubectl get pods -n monitoring`
- Check service: `kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus`
- Use internal DNS: `http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`

**4. Loki not receiving logs**

```bash
# Check Promtail logs
kubectl logs -n monitoring -l app=promtail

# Verify Loki is running
kubectl get pods -n monitoring -l app=loki
```

**5. Port forwarding disconnects**

- Use `nohup` for persistent port forwarding:

```bash
nohup kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0' &
```

## Report Template

Use the template in `docs/report-template.md` to create your PDF report.

Required screenshots:

1. ✅ EC2 instance running in AWS Console
2. ✅ Minikube status output
3. ✅ Sample application pods running
4. ✅ Prometheus pods running
5. ✅ Grafana login page
6. ✅ Grafana metrics dashboard (CPU/Memory panels)
7. ✅ Loki data source configured
8. ✅ Application logs in Grafana

## Key Metrics to Monitor

### CPU Usage

- **Query**: `sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)`
- **Purpose**: Track CPU consumption trends

### Memory Usage

- **Query**: `sum(container_memory_working_set_bytes) by (pod)`
- **Purpose**: Monitor memory consumption

### Pod Availability

- **Query**: `kube_pod_status_phase{phase="Running"}`
- **Purpose**: Track pod health

### Node Status

- **Query**: `kube_node_status_condition{condition="Ready"}`
- **Purpose**: Monitor node health

## LogQL Queries for Loki

```logql
# All logs from application namespace
{namespace="application"}

# Error logs only
{namespace="application"} |= "error"

# Nginx access logs
{namespace="application",app="nginx"} |~ "GET|POST"

# Last 5 minutes with rate
rate({namespace="application"}[5m])
```

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│              AWS EC2 Instance                    │
│  ┌───────────────────────────────────────────┐  │
│  │         Minikube Cluster                  │  │
│  │                                           │  │
│  │  ┌─────────────────────┐                 │  │
│  │  │  Application NS     │                 │  │
│  │  │  - Nginx Pods       │                 │  │
│  │  └─────────────────────┘                 │  │
│  │                                           │  │
│  │  ┌─────────────────────────────────────┐ │  │
│  │  │  Monitoring NS                      │ │  │
│  │  │  ┌──────────┐  ┌─────────┐         │ │  │
│  │  │  │Prometheus│  │ Grafana │         │ │  │
│  │  │  └──────────┘  └─────────┘         │ │  │
│  │  │  ┌──────────┐  ┌─────────┐         │ │  │
│  │  │  │   Loki   │  │Promtail │         │ │  │
│  │  │  └──────────┘  └─────────┘         │ │  │
│  │  └─────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## Technologies Used

- **Kubernetes**: Container orchestration (via Minikube)
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboarding
- **Loki**: Log aggregation
- **Promtail**: Log collector
- **Helm**: Kubernetes package manager
- **Docker**: Container runtime

## Learning Outcomes

After completing this project, you will understand:

- How to set up a Kubernetes cluster on EC2
- Implementing monitoring with Prometheus
- Creating custom Grafana dashboards
- Log aggregation with Loki
- PromQL and LogQL query languages
- Kubernetes resource management
- Troubleshooting containerized applications

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

## License

MIT License - Feel free to use this project for learning purposes.

## Author

OSTAD 2025 - Module 7 Assignment

---

**Good luck with your assignment! 🚀**

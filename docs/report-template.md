# Module 7 Project: Kubernetes Monitoring & Logging Dashboard

## Assignment Report

**Student Name:** [Your Name]  
**Student ID:** [Your ID]  
**Course:** OSTAD 2025 - DevOps  
**Module:** 7 - Kubernetes Monitoring & Logging  
**Date:** [Submission Date]

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Project Objectives](#project-objectives)
3. [Implementation Steps](#implementation-steps)
4. [Screenshots](#screenshots)
5. [Dashboard Panels Explanation](#dashboard-panels-explanation)
6. [Challenges and Solutions](#challenges-and-solutions)
7. [Conclusion](#conclusion)
8. [References](#references)

---

## Executive Summary

This report documents the implementation of a comprehensive Kubernetes monitoring and logging solution using Prometheus, Grafana, and Loki on a Minikube cluster hosted on AWS EC2. The project demonstrates end-to-end setup of observability tools for Kubernetes workloads.

**Key Achievements:**

- ✅ Successfully deployed Minikube cluster on AWS EC2
- ✅ Implemented Prometheus for metrics collection
- ✅ Configured Grafana dashboards for visualization
- ✅ Deployed Loki and Promtail for log aggregation
- ✅ Created custom dashboards for cluster and application monitoring

---

## Project Objectives

The primary objectives of this project were:

1. **Cluster Setup**: Deploy a Minikube cluster on an AWS EC2 instance running Ubuntu
2. **Application Deployment**: Deploy a sample Nginx application in the `application` namespace
3. **Metrics Monitoring**: Implement Prometheus and Grafana for cluster and application metrics
4. **Log Aggregation**: Deploy Loki and Promtail for centralized logging
5. **Visualization**: Create comprehensive Grafana dashboards for both metrics and logs

---

## Implementation Steps

### Phase 1: AWS EC2 Instance Setup

#### 1.1 EC2 Instance Configuration

**Instance Specifications:**

- **AMI**: Ubuntu 22.04 LTS (64-bit x86)
- **Instance Type**: t3.medium (2 vCPU, 4 GB RAM)
- **Storage**: 30 GB gp3
- **Region**: [Your Region]
- **Availability Zone**: [Your AZ]

**Security Group Rules:**

```
Inbound Rules:
- SSH (22): Your IP
- HTTP (80): Your IP
- HTTPS (443): Your IP
- Custom TCP 3000: Your IP (Grafana)
- Custom TCP 9090: Your IP (Prometheus)
- Custom TCP 30000-32767: Your IP (NodePort services)
```

#### 1.2 System Setup

Connected to EC2 instance:

```bash
ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>
```

Ran the setup script to install:

- Docker (version: [version])
- kubectl (version: [version])
- Helm (version: [version])
- Additional dependencies

**Screenshot Required:** EC2 instance details from AWS Console

---

### Phase 2: Minikube Cluster Deployment

#### 2.1 Minikube Installation

Executed the Minikube installation script:

```bash
./scripts/02-install-minikube.sh
```

**Cluster Configuration:**

- Driver: Docker
- CPUs: 2
- Memory: 4096 MB
- Disk: 20 GB
- Kubernetes Version: [version]

#### 2.2 Cluster Verification

Verified cluster status:

```bash
minikube status
kubectl get nodes
kubectl get pods -A
```

**Screenshot Required:** Minikube status output showing cluster running

---

### Phase 3: Sample Application Deployment

#### 3.1 Namespace Creation

Created the `application` namespace:

```bash
kubectl apply -f manifests/namespace/application-namespace.yaml
```

#### 3.2 Nginx Deployment

Deployed Nginx application with:

- 3 replicas
- Resource limits (CPU: 200m, Memory: 128Mi)
- Health checks (liveness and readiness probes)
- NodePort service on port 30080

```bash
kubectl apply -f manifests/application/
```

#### 3.3 Application Verification

Verified deployment:

```bash
kubectl get all -n application
kubectl describe deployment nginx-deployment -n application
```

**Screenshot Required:** Running Nginx pods in application namespace

---

### Phase 4: Prometheus and Grafana Setup

#### 4.1 Helm Repository Configuration

Added Prometheus community Helm repository:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

#### 4.2 Prometheus Stack Installation

Installed kube-prometheus-stack:

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace \
  -f manifests/prometheus/values.yaml
```

**Components Installed:**

- Prometheus Operator
- Prometheus Server
- Grafana
- Alertmanager
- Node Exporter
- Kube State Metrics

#### 4.3 Grafana Access

Retrieved Grafana credentials:

```bash
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
```

**Grafana Credentials:**

- Username: admin
- Password: [Retrieved password]

Port forwarded Grafana service:

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'
```

**Screenshot Required:**

- Grafana login page
- Grafana home dashboard

---

### Phase 5: Loki and Promtail Deployment

#### 5.1 Loki Deployment

Deployed Loki for log aggregation:

```bash
kubectl apply -f manifests/loki/loki.yaml
```

**Loki Configuration:**

- Storage: Filesystem (10 GB PVC)
- Retention: 7 days
- Port: 3100

#### 5.2 Promtail Deployment

Deployed Promtail as DaemonSet:

```bash
kubectl apply -f manifests/loki/promtail.yaml
```

**Promtail Configuration:**

- Runs on all nodes (DaemonSet)
- Collects logs from `/var/log/pods`
- Forwards to Loki service
- Filters logs by namespace and pod labels

#### 5.3 Loki Data Source Configuration

Added Loki as data source in Grafana:

- URL: `http://loki.monitoring.svc.cluster.local:3100`
- Access: Server (proxy)

**Screenshot Required:** Loki data source configured and tested in Grafana

---

### Phase 6: Grafana Dashboards

#### 6.1 Metrics Dashboard

Created comprehensive metrics dashboard with panels:

**Dashboard Panels:**

1. Total Nodes (Stat)
2. Total Pods (Stat)
3. CPU Usage % (Gauge)
4. Memory Usage % (Gauge)
5. CPU Usage by Node (Time Series)
6. Memory Usage by Node (Time Series)
7. Pod Status by Phase (Time Series)
8. Pod Restart Count (Time Series)
9. CPU Usage by Pod (Time Series)
10. Memory Usage by Pod (Time Series)

#### 6.2 Logs Dashboard

Created logs dashboard with panels:

**Dashboard Panels:**

1. Log Rate by Level (Time Series - INFO/WARN/ERROR)
2. All Application Logs (Logs panel)
3. Error Logs (Filtered logs panel)
4. Warning Logs (Filtered logs panel)
5. Nginx Application Logs (Filtered by app label)
6. Log Rate by Pod (Time Series)

**Screenshot Required:**

- Metrics dashboard showing all panels
- Logs dashboard showing log streams

---

## Screenshots

### 1. AWS EC2 Instance Setup

![EC2 Instance Running](screenshots/01-ec2-instance.png)
_Screenshot showing EC2 instance in running state with specifications_

### 2. Minikube Cluster

![Minikube Status](screenshots/02-minikube-status.png)
_Screenshot of `minikube status` command output_

### 3. Application Deployment

![Application Pods](screenshots/03-application-pods.png)
_Screenshot showing Nginx pods running in application namespace_

### 4. Prometheus Monitoring

![Prometheus Pods](screenshots/04-prometheus-pods.png)
_Screenshot showing all Prometheus stack components running_

### 5. Grafana Login

![Grafana Login](screenshots/05-grafana-login.png)
_Screenshot of Grafana login page_

### 6. Grafana Metrics Dashboard

![Metrics Dashboard Overview](screenshots/06-metrics-dashboard-1.png)
_Screenshot of cluster metrics dashboard - Part 1_

![Metrics Dashboard Graphs](screenshots/07-metrics-dashboard-2.png)
_Screenshot of cluster metrics dashboard - Part 2_

### 7. Loki Data Source

![Loki Configuration](screenshots/08-loki-datasource.png)
_Screenshot showing Loki configured as data source_

### 8. Logs Dashboard

![Logs Dashboard](screenshots/09-logs-dashboard.png)
_Screenshot of application logs dashboard with log panels_

### 9. Real-time Monitoring

![Live Metrics](screenshots/10-live-metrics.png)
_Screenshot showing real-time metrics updating_

---

## Dashboard Panels Explanation

### Metrics Dashboard

#### 1. Total Nodes Panel

- **Type**: Stat
- **Query**: `count(kube_node_info)`
- **Purpose**: Displays the total number of nodes in the cluster
- **Use Case**: Quick overview of cluster size

#### 2. Total Pods Panel

- **Type**: Stat
- **Query**: `count(kube_pod_info)`
- **Purpose**: Shows total number of pods across all namespaces
- **Use Case**: Monitor cluster workload capacity

#### 3. CPU Usage % Panel

- **Type**: Gauge
- **Query**: `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- **Purpose**: Displays cluster-wide CPU utilization percentage
- **Thresholds**:
  - Green: 0-70%
  - Yellow: 70-90%
  - Red: >90%
- **Use Case**: Identify CPU resource pressure

#### 4. Memory Usage % Panel

- **Type**: Gauge
- **Query**: `100 * (1 - ((avg_over_time(node_memory_MemFree_bytes[5m]) + ...) / avg_over_time(node_memory_MemTotal_bytes[5m])))`
- **Purpose**: Shows memory utilization across the cluster
- **Thresholds**: Same as CPU
- **Use Case**: Monitor memory pressure and potential OOM scenarios

#### 5. CPU Usage by Node

- **Type**: Time Series
- **Query**: `100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- **Purpose**: Track CPU usage trends per node over time
- **Use Case**: Identify nodes with high CPU load for capacity planning

#### 6. Memory Usage by Node

- **Type**: Time Series
- **Query**: `node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Cached_bytes - node_memory_Buffers_bytes`
- **Purpose**: Monitor memory consumption per node
- **Use Case**: Detect memory leaks or high-memory workloads

#### 7. Pod Status (Application Namespace)

- **Type**: Time Series
- **Query**: `sum by (phase) (kube_pod_status_phase{namespace="application"})`
- **Purpose**: Track pod lifecycle states (Running, Pending, Failed)
- **Use Case**: Monitor application health and deployment issues

#### 8. Pod Restart Count

- **Type**: Time Series
- **Query**: `sum by (pod) (kube_pod_container_status_restarts_total{namespace="application"})`
- **Purpose**: Track pod restart events
- **Use Case**: Identify crashloop backoffs and application stability issues

#### 9. CPU Usage by Pod

- **Type**: Time Series
- **Query**: `sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="application"}[5m]))`
- **Purpose**: Monitor CPU consumption per pod
- **Use Case**: Identify CPU-intensive pods and optimize resource requests

#### 10. Memory Usage by Pod

- **Type**: Time Series
- **Query**: `sum by (pod) (container_memory_working_set_bytes{namespace="application"})`
- **Purpose**: Track memory usage per pod
- **Use Case**: Detect memory leaks and set appropriate memory limits

### Logs Dashboard

#### 1. Log Rate by Level

- **Type**: Time Series
- **LogQL**: `sum by (level) (count_over_time({namespace="application"} | logfmt | level=~"INFO|WARN|ERROR" [1m]))`
- **Purpose**: Visualize log volume by severity level
- **Use Case**: Detect error spikes and application issues

#### 2. All Application Logs

- **Type**: Logs
- **LogQL**: `{namespace="application"}`
- **Purpose**: Stream all logs from application namespace
- **Use Case**: Real-time debugging and troubleshooting

#### 3. Error Logs

- **Type**: Logs
- **LogQL**: `{namespace="application"} |~ "(?i)error"`
- **Purpose**: Filter and display only error logs
- **Use Case**: Quick error investigation

#### 4. Warning Logs

- **Type**: Logs
- **LogQL**: `{namespace="application"} |~ "(?i)warn"`
- **Purpose**: Show warning-level logs
- **Use Case**: Identify potential issues before they become errors

#### 5. Nginx Application Logs

- **Type**: Logs
- **LogQL**: `{namespace="application", app="nginx"}`
- **Purpose**: Filter logs specific to Nginx application
- **Use Case**: Application-specific debugging

#### 6. Log Rate by Pod

- **Type**: Time Series
- **LogQL**: `sum by (pod) (rate({namespace="application"}[1m]))`
- **Purpose**: Compare log output rate across pods
- **Use Case**: Identify noisy pods or pods with issues

---

## Challenges and Solutions

### Challenge 1: EC2 Instance Resource Constraints

**Problem**: Initial t2.micro instance was insufficient for running Minikube with all monitoring components.

**Symptoms**:

- Minikube start failures
- Pods stuck in Pending state
- OOM (Out of Memory) errors

**Solution**:

- Upgraded to t3.medium instance (2 vCPU, 4 GB RAM)
- Configured Minikube with explicit resource limits: `--memory=4096 --cpus=2`
- Set resource requests and limits for all deployments

**Learning**: Always plan for overhead when running monitoring tools alongside applications.

---

### Challenge 2: Prometheus Stack Installation Timeout

**Problem**: Helm installation of kube-prometheus-stack timing out during deployment.

**Symptoms**:

```
Error: timed out waiting for the condition
```

**Solution**:

- Increased timeout: `helm install ... --timeout 10m`
- Verified Docker daemon is running properly
- Checked image pull status: `kubectl describe pod -n monitoring`
- Pre-pulled critical images on Minikube

**Learning**: Large Helm charts with multiple components need adequate timeout periods.

---

### Challenge 3: Loki Not Receiving Logs from Promtail

**Problem**: Loki dashboard showed no logs even though Promtail was running.

**Symptoms**:

- Empty log panels in Grafana
- Promtail showing "connection refused" errors

**Root Cause**: Incorrect Loki service URL in Promtail configuration.

**Solution**:

1. Verified Loki service DNS: `kubectl get svc -n monitoring loki`
2. Updated Promtail config to use FQDN: `http://loki.monitoring.svc.cluster.local:3100`
3. Checked Promtail logs: `kubectl logs -n monitoring -l app=promtail`
4. Restarted Promtail DaemonSet

**Learning**: Always use fully qualified domain names (FQDN) for cross-namespace service communication.

---

### Challenge 4: Port Forwarding Disconnecting

**Problem**: Port forwarding sessions dropping after a few minutes.

**Symptoms**:

- Unable to access Grafana UI intermittently
- Connection reset errors

**Solution**:

```bash
# Use nohup for persistent port forwarding
nohup kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0' &

# Alternative: Use screen or tmux
screen -S grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'
# Press Ctrl+A, then D to detach
```

**Learning**: Long-running port forwards should be managed in background sessions.

---

### Challenge 5: Dashboard Queries Not Returning Data

**Problem**: Some Prometheus queries in dashboards showing "No Data".

**Symptoms**:

- Empty panels despite metrics being available
- Query inspector showing no results

**Root Cause**:

- Incorrect label selectors
- Metrics not yet available for the time range
- ServiceMonitor not properly configured

**Solution**:

1. Verified metrics in Prometheus UI: `http://<EC2-IP>:9090`
2. Tested queries directly in Prometheus before adding to Grafana
3. Adjusted time range to match data availability
4. Fixed label selectors to match actual metric labels
5. Applied ServiceMonitor for application metrics

**Example Fix**:

```promql
# Before (not working)
container_cpu_usage_seconds_total{pod="nginx"}

# After (working)
container_cpu_usage_seconds_total{namespace="application", container!=""}
```

**Learning**: Always validate PromQL queries in Prometheus before creating dashboard panels.

---

### Challenge 6: Grafana Dashboard Permissions

**Problem**: Unable to save dashboard changes.

**Solution**:

- Used admin credentials
- Configured proper dashboard provisioning via ConfigMaps
- Set dashboard permissions appropriately

---

## Key Learnings

1. **Resource Planning**: Monitoring tools require significant resources; plan EC2 instance size accordingly
2. **Networking**: Understanding Kubernetes DNS and service discovery is critical for inter-service communication
3. **Observability**: Metrics and logs together provide comprehensive visibility into system health
4. **Query Languages**: PromQL and LogQL are powerful but require practice to master
5. **Troubleshooting**: Always check logs, events, and descriptions when pods fail to start

---

## Conclusion

This project successfully demonstrated the implementation of a complete monitoring and logging solution for Kubernetes using industry-standard tools. The combination of Prometheus for metrics, Grafana for visualization, and Loki for log aggregation provides comprehensive observability into cluster health and application behavior.

### Achievements

✅ **Infrastructure**: Successfully deployed and configured Minikube on AWS EC2  
✅ **Monitoring**: Implemented Prometheus with custom dashboards showing CPU, memory, and pod metrics  
✅ **Logging**: Configured Loki and Promtail for centralized log aggregation  
✅ **Visualization**: Created user-friendly Grafana dashboards for both metrics and logs  
✅ **Documentation**: Comprehensive documentation with troubleshooting guides

### Production Readiness Considerations

For a production deployment, the following enhancements would be recommended:

1. **High Availability**:

   - Multi-node Kubernetes cluster (not Minikube)
   - Replicated Prometheus and Loki instances
   - Load-balanced Grafana

2. **Persistence**:

   - Persistent storage for Prometheus TSDB
   - Object storage (S3) for Loki chunks
   - Backup and disaster recovery procedures

3. **Security**:

   - TLS/SSL for all communication
   - OAuth/LDAP integration for Grafana
   - Network policies for pod-to-pod communication
   - Secrets management (Vault, Sealed Secrets)

4. **Scalability**:

   - Prometheus federation or Thanos for long-term storage
   - Loki distributed mode for high-volume logs
   - Resource autoscaling

5. **Alerting**:
   - Configure Alertmanager rules
   - Integration with PagerDuty, Slack, etc.
   - Alert routing and escalation policies

### Skills Developed

Through this project, I have gained hands-on experience with:

- AWS EC2 instance management
- Kubernetes cluster administration
- Helm package management
- Prometheus metrics collection and PromQL queries
- Loki log aggregation and LogQL queries
- Grafana dashboard creation and customization
- Troubleshooting containerized applications
- DevOps best practices for observability

---

## References

1. **Prometheus**:

   - [Official Documentation](https://prometheus.io/docs/)
   - [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)

2. **Grafana**:

   - [Official Documentation](https://grafana.com/docs/)
   - [Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)

3. **Loki**:

   - [Official Documentation](https://grafana.com/docs/loki/latest/)
   - [LogQL Guide](https://grafana.com/docs/loki/latest/logql/)

4. **Kubernetes**:

   - [Kubernetes Documentation](https://kubernetes.io/docs/)
   - [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

5. **Helm**:

   - [Helm Documentation](https://helm.sh/docs/)
   - [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

6. **AWS**:
   - [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
   - [AWS Best Practices](https://aws.amazon.com/architecture/well-architected/)

---

## Appendix

### A. Important Commands Reference

```bash
# Cluster Management
minikube start
minikube status
minikube stop
minikube delete

# Kubernetes
kubectl get pods -A
kubectl get svc -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>

# Helm
helm list -A
helm install <release> <chart> -n <namespace>
helm upgrade <release> <chart> -n <namespace>
helm uninstall <release> -n <namespace>

# Port Forwarding
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Troubleshooting
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
kubectl top nodes
kubectl top pods -A
```

### B. Useful PromQL Queries

```promql
# CPU Usage
rate(container_cpu_usage_seconds_total[5m])

# Memory Usage
container_memory_working_set_bytes

# Pod Count
count(kube_pod_info)

# Node Status
kube_node_status_condition{condition="Ready"}

# Disk Usage
node_filesystem_avail_bytes / node_filesystem_size_bytes * 100
```

### C. Useful LogQL Queries

```logql
# All logs from namespace
{namespace="application"}

# Error logs
{namespace="application"} |= "error"

# JSON parsing
{namespace="application"} | json | level="ERROR"

# Rate of logs
rate({namespace="application"}[5m])

# Pattern extraction
{namespace="application"} | regexp "(?P<method>\\w+) (?P<path>/\\S+)"
```

---

**Report Submitted By:**  
[Your Name]  
[Your Email]  
[Date]

---

**GitHub Repository:** [If applicable, add link to your GitHub repo with configuration files]

---

**End of Report**

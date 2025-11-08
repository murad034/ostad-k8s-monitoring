# Project File Index

Complete index of all files in the Kubernetes Monitoring & Logging Dashboard project.

## 📋 Quick Navigation

- [Root Files](#root-files)
- [Scripts](#scripts)
- [Manifests](#manifests)
- [Dashboards](#dashboards)
- [Documentation](#documentation)

---

## Root Files

### README.md

- **Purpose**: Main project documentation
- **Contains**: Complete setup instructions, architecture, commands
- **Audience**: Everyone
- **When to read**: Start here

### QUICKSTART.md

- **Purpose**: Fast 30-minute setup guide
- **Contains**: Condensed step-by-step instructions
- **Audience**: Users who want quick deployment
- **When to read**: When you want to get started immediately

### PROJECT_SUMMARY.md

- **Purpose**: Project overview and summary
- **Contains**: Features, technologies, architecture, statistics
- **Audience**: Instructors, reviewers
- **When to read**: For project overview

### .gitignore

- **Purpose**: Git ignore rules
- **Contains**: Files/folders to exclude from version control
- **Audience**: Developers
- **When to use**: When committing to Git

---

## Scripts

Location: `scripts/`

### 01-ec2-setup.sh

- **Purpose**: EC2 instance initial setup
- **Installs**: Docker, kubectl, Helm, dependencies
- **Run time**: ~5-10 minutes
- **Usage**: `./scripts/01-ec2-setup.sh`
- **Prerequisites**: Fresh Ubuntu 22.04 EC2 instance

### 02-install-minikube.sh

- **Purpose**: Install and configure Minikube
- **Installs**: Minikube, starts cluster, enables addons
- **Run time**: ~5 minutes
- **Usage**: `./scripts/02-install-minikube.sh`
- **Prerequisites**: 01-ec2-setup.sh completed

### 03-deploy-all.sh

- **Purpose**: Deploy complete monitoring stack
- **Deploys**: Namespaces, app, Prometheus, Grafana, Loki, Promtail
- **Run time**: ~10-15 minutes
- **Usage**: `./scripts/03-deploy-all.sh`
- **Prerequisites**: Minikube running

### 04-cleanup.sh

- **Purpose**: Remove all deployed components
- **Removes**: All resources, namespaces
- **Run time**: ~2 minutes
- **Usage**: `./scripts/04-cleanup.sh`
- **Warning**: Destructive operation

### verify.sh

- **Purpose**: Verify entire stack is working
- **Checks**: Cluster, pods, services, connectivity
- **Run time**: ~1 minute
- **Usage**: `./scripts/verify.sh`
- **When to run**: After deployment

### port-forward.sh

- **Purpose**: Manage port forwarding for services
- **Features**: Start, stop, restart, status
- **Usage**: `./scripts/port-forward.sh start`
- **Options**: `start|stop|restart|status|logs`

---

## Manifests

Location: `manifests/`

### Namespace Manifests

Location: `manifests/namespace/`

#### application-namespace.yaml

- **Creates**: `application` namespace
- **Purpose**: Isolate application workloads
- **Labels**: `name: application, purpose: sample-app`

#### monitoring-namespace.yaml

- **Creates**: `monitoring` namespace
- **Purpose**: Isolate monitoring stack
- **Labels**: `name: monitoring, purpose: observability`

### Application Manifests

Location: `manifests/application/`

#### nginx-deployment.yaml

- **Creates**: Deployment, Service, ConfigMap
- **Replicas**: 3
- **Resources**: 100m CPU, 64Mi RAM (request), 200m CPU, 128Mi RAM (limit)
- **Port**: 80 (container), 30080 (NodePort)
- **Health checks**: Liveness and readiness probes

#### nginx-html.yaml

- **Creates**: ConfigMap with custom HTML
- **Purpose**: Custom landing page
- **Content**: Interactive dashboard info page

### Prometheus Manifests

Location: `manifests/prometheus/`

#### values.yaml

- **Type**: Helm values file
- **For**: kube-prometheus-stack chart
- **Configures**: Prometheus, Grafana, Alertmanager settings
- **Storage**: 10Gi for Prometheus, 5Gi for Grafana
- **Features**: Pre-loaded dashboards, data sources

#### servicemonitor.yaml

- **Type**: ServiceMonitor CRD
- **Purpose**: Configure Prometheus to scrape Nginx metrics
- **Target**: Nginx service in application namespace

### Loki Manifests

Location: `manifests/loki/`

#### loki.yaml

- **Creates**: ConfigMap, StatefulSet, Service
- **Storage**: 10Gi PVC
- **Retention**: 7 days
- **Port**: 3100

#### promtail.yaml

- **Creates**: ConfigMap, DaemonSet, ServiceAccount, RBAC
- **Type**: DaemonSet (runs on all nodes)
- **Purpose**: Collect and forward logs to Loki
- **Permissions**: ClusterRole for pod/node access

### Grafana Manifests

Location: `manifests/grafana/`

#### dashboard-metrics.yaml

- **Type**: ConfigMap
- **Contains**: Kubernetes cluster metrics dashboard JSON
- **Panels**: 11 panels (CPU, Memory, Pods, Nodes, Trends)
- **Data source**: Prometheus

#### dashboard-logs.yaml

- **Type**: ConfigMap
- **Contains**: Application logs dashboard JSON
- **Panels**: 8 panels (Log streams, filters, rates)
- **Data source**: Loki

---

## Dashboards

Location: `dashboards/`

### k8s-cluster-metrics.json

- **Type**: Grafana dashboard JSON
- **Purpose**: Cluster and application metrics visualization
- **Panels**:
  - Total Nodes (Stat)
  - Total Pods (Stat)
  - CPU Usage % (Gauge)
  - Memory Usage % (Gauge)
  - CPU Usage by Node (Time Series)
  - Memory Usage by Node (Time Series)
  - Pod Status (Time Series)
  - Pod Restart Count (Time Series)
  - CPU Usage by Pod (Time Series)
  - Memory Usage by Pod (Time Series)
- **Refresh**: 10s
- **Time range**: Last 1 hour (default)

### application-logs.json

- **Type**: Grafana dashboard JSON
- **Purpose**: Application log visualization
- **Panels**:
  - Dashboard Info (Text)
  - Log Rate by Level (Time Series)
  - All Application Logs (Logs)
  - Error Logs (Logs - filtered)
  - Warning Logs (Logs - filtered)
  - Nginx Application Logs (Logs - filtered)
  - Log Rate by Pod (Time Series)
- **Refresh**: 10s
- **Features**: LogQL queries, filtering

---

## Documentation

Location: `docs/`

### report-template.md

- **Purpose**: Assignment report template
- **Sections**:
  - Executive Summary
  - Implementation Steps
  - Screenshots
  - Dashboard Explanations
  - Challenges and Solutions
  - Conclusion
- **Length**: ~40 pages
- **Format**: Markdown (convert to PDF for submission)

### TROUBLESHOOTING.md

- **Purpose**: Common issues and solutions
- **Sections**:
  - EC2 and System Issues
  - Minikube Issues
  - Application Deployment Issues
  - Prometheus Issues
  - Grafana Issues
  - Loki and Promtail Issues
  - Networking Issues
  - Resource Issues
- **Length**: Comprehensive guide
- **When to use**: When encountering problems

### COMMANDS.md

- **Purpose**: Command reference cheat sheet
- **Sections**:
  - AWS EC2 Commands
  - System Commands
  - Minikube Commands
  - Kubectl Commands
  - Helm Commands
  - Project-Specific Commands
  - Monitoring Queries
  - Troubleshooting Commands
- **Features**: Copy-paste ready commands
- **Includes**: Useful aliases

### screenshots/README.md

- **Purpose**: Screenshot requirements and guidelines
- **Contains**:
  - Checklist of required screenshots
  - How to take screenshots
  - Best practices
  - Naming conventions
- **Required screenshots**: 11+

---

## File Usage Matrix

| File                   | Setup | Deploy | Debug | Report |
| ---------------------- | ----- | ------ | ----- | ------ |
| README.md              | ✓     | ✓      | ✓     | ✓      |
| QUICKSTART.md          | ✓     | ✓      | -     | -      |
| 01-ec2-setup.sh        | ✓     | -      | -     | -      |
| 02-install-minikube.sh | ✓     | -      | -     | -      |
| 03-deploy-all.sh       | -     | ✓      | -     | -      |
| verify.sh              | -     | ✓      | ✓     | -      |
| port-forward.sh        | -     | ✓      | -     | -      |
| TROUBLESHOOTING.md     | -     | -      | ✓     | ✓      |
| COMMANDS.md            | ✓     | ✓      | ✓     | -      |
| report-template.md     | -     | -      | -     | ✓      |

---

## Execution Order

### First Time Setup

1. ✅ Read `README.md`
2. ✅ Launch EC2 instance
3. ✅ Run `01-ec2-setup.sh`
4. ✅ Run `02-install-minikube.sh`
5. ✅ Run `03-deploy-all.sh`
6. ✅ Run `verify.sh`
7. ✅ Run `port-forward.sh start`
8. ✅ Access Grafana and configure

### Quick Restart

1. ✅ `minikube start`
2. ✅ Run `verify.sh`
3. ✅ Run `port-forward.sh start`

### Troubleshooting

1. ✅ Check `TROUBLESHOOTING.md`
2. ✅ Run `verify.sh`
3. ✅ Check specific logs
4. ✅ Use `COMMANDS.md` for reference

### Report Writing

1. ✅ Take screenshots (use `screenshots/README.md`)
2. ✅ Use `report-template.md`
3. ✅ Fill in all sections
4. ✅ Convert to PDF

---

## File Sizes (Approximate)

| File                   | Lines | Size   |
| ---------------------- | ----- | ------ |
| README.md              | ~450  | ~30 KB |
| QUICKSTART.md          | ~350  | ~20 KB |
| PROJECT_SUMMARY.md     | ~400  | ~25 KB |
| report-template.md     | ~1200 | ~80 KB |
| TROUBLESHOOTING.md     | ~900  | ~60 KB |
| COMMANDS.md            | ~650  | ~40 KB |
| dashboard-metrics.yaml | ~600  | ~40 KB |
| dashboard-logs.yaml    | ~400  | ~25 KB |

---

## Quick Access by Task

### I want to deploy quickly

→ `QUICKSTART.md`

### I want complete instructions

→ `README.md`

### I have an error

→ `TROUBLESHOOTING.md`

### I need a command

→ `COMMANDS.md`

### I need to write the report

→ `report-template.md`

### I need to verify everything works

→ `scripts/verify.sh`

### I want to understand the project

→ `PROJECT_SUMMARY.md`

### I need to manage port forwards

→ `scripts/port-forward.sh`

---

## File Dependencies

```
EC2 Instance
    ↓
01-ec2-setup.sh
    ↓
02-install-minikube.sh
    ↓
manifests/namespace/*.yaml
    ↓
manifests/application/*.yaml
    ↓
manifests/prometheus/values.yaml
    ↓
manifests/loki/*.yaml
    ↓
manifests/grafana/*.yaml
    ↓
verify.sh (validation)
    ↓
port-forward.sh (access)
    ↓
Grafana UI (visualization)
```

---

## Resource Allocation by Component

| Component    | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage |
| ------------ | ----------- | --------- | -------------- | ------------ | ------- |
| Nginx (each) | 100m        | 200m      | 64Mi           | 128Mi        | -       |
| Prometheus   | 200m        | 500m      | 512Mi          | 1Gi          | 10Gi    |
| Grafana      | 100m        | 300m      | 256Mi          | 512Mi        | 5Gi     |
| Loki         | 100m        | 500m      | 256Mi          | 512Mi        | 10Gi    |
| Promtail     | 50m         | 200m      | 128Mi          | 256Mi        | -       |
| Alertmanager | 50m         | 100m      | 128Mi          | 256Mi        | -       |

**Total Cluster Requirements**: 2 CPU, 4GB RAM, 30GB Disk

---

## Support Matrix

| Issue Type       | Primary Resource   | Secondary Resource    |
| ---------------- | ------------------ | --------------------- |
| Setup problems   | QUICKSTART.md      | README.md             |
| Pod failures     | TROUBLESHOOTING.md | verify.sh             |
| Command syntax   | COMMANDS.md        | kubectl help          |
| Port forwarding  | port-forward.sh    | TROUBLESHOOTING.md    |
| Dashboard issues | TROUBLESHOOTING.md | Grafana docs          |
| Report writing   | report-template.md | screenshots/README.md |

---

## Version Control

Recommended `.gitignore` patterns:

- `*.pem` (SSH keys)
- `*.log` (Log files)
- `docs/screenshots/*.png` (Optional)
- `secrets/` (Credentials)

Safe to commit:

- All `.yaml` files
- All `.sh` files
- All `.md` files
- Dashboard `.json` files

---

**Last Updated**: November 2025  
**Project**: Kubernetes Monitoring & Logging Dashboard  
**Course**: OSTAD 2025 - DevOps Module 7

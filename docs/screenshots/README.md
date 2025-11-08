# Screenshots Guide

This folder contains all screenshots required for the assignment report.

## Required Screenshots Checklist

### 1. AWS EC2 Setup

- [ ] **01-ec2-instance.png** - EC2 instance running in AWS Console showing:
  - Instance ID
  - Instance type (t3.medium)
  - Running state
  - Public IP address
  - Security group

### 2. Minikube Cluster

- [ ] **02-minikube-status.png** - Terminal output of `minikube status` showing:
  - minikube: Running
  - kubelet: Running
  - apiserver: Running

### 3. Application Deployment

- [ ] **03-application-pods.png** - Terminal output of `kubectl get pods -n application` showing:
  - All nginx pods in Running state
  - Ready status (1/1)
  - Restarts count

### 4. Monitoring Stack

- [ ] **04-prometheus-pods.png** - Terminal output of `kubectl get pods -n monitoring` showing:
  - Prometheus pods
  - Grafana pod
  - Alertmanager pods
  - All in Running state

### 5. Grafana UI

- [ ] **05-grafana-login.png** - Grafana login page at http://<EC2-IP>:3000
- [ ] **06-grafana-home.png** - Grafana home dashboard after login

### 6. Metrics Dashboard

- [ ] **06-metrics-dashboard-1.png** - Top section of metrics dashboard showing:

  - Total Nodes stat
  - Total Pods stat
  - CPU Usage gauge
  - Memory Usage gauge

- [ ] **07-metrics-dashboard-2.png** - Bottom section showing:
  - CPU usage by node graph
  - Memory usage by node graph
  - Pod status graph
  - Resource trends

### 7. Loki Configuration

- [ ] **08-loki-datasource.png** - Grafana data sources page showing:
  - Loki configured
  - Green checkmark indicating successful connection
  - URL: http://loki.monitoring.svc.cluster.local:3100

### 8. Logs Dashboard

- [ ] **09-logs-dashboard.png** - Application logs dashboard showing:
  - Log rate by level graph
  - All application logs panel
  - Error logs panel
  - Real-time log stream

### 9. Live Monitoring

- [ ] **10-live-metrics.png** - Dashboard with live data updating
- [ ] **11-prometheus-ui.png** - Prometheus UI at http://<EC2-IP>:9090

## How to Take Screenshots

### On Windows

1. **Snipping Tool**: Windows + Shift + S
2. **Full Screen**: PrtScn key
3. **Active Window**: Alt + PrtScn

### On macOS

1. **Full Screen**: Cmd + Shift + 3
2. **Selection**: Cmd + Shift + 4
3. **Window**: Cmd + Shift + 4, then Space

### On Linux

1. **Gnome Screenshot**: PrtScn key
2. **Flameshot**: `flameshot gui`
3. **Spectacle**: Shift + PrtScn

## Screenshot Best Practices

1. **Resolution**: Use at least 1920x1080 for clarity
2. **Format**: PNG format preferred (lossless)
3. **Annotations**: Add arrows or highlights to important elements
4. **Naming**: Follow the naming convention above
5. **Visibility**: Ensure all text is readable
6. **Privacy**: Hide/redact sensitive information (IPs, credentials if needed)

## Terminal Screenshots

For terminal screenshots, ensure:

- Full command is visible
- Output is complete
- Timestamp is shown (if applicable)
- Terminal prompt shows the correct directory/user

### Example Commands to Screenshot

```bash
# EC2 System Info
uname -a
free -h
df -h

# Minikube Status
minikube status
kubectl version
kubectl get nodes

# Application
kubectl get all -n application
kubectl describe deployment nginx-deployment -n application

# Monitoring
kubectl get pods -n monitoring
kubectl get svc -n monitoring
helm list -n monitoring

# Grafana Password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
```

## Grafana Dashboard Screenshots

When taking Grafana screenshots:

1. Set time range to show meaningful data (e.g., Last 1 hour)
2. Ensure all panels have loaded
3. Show the dashboard in full-screen mode (TV mode)
4. Capture both the dashboard and the data

### Grafana Settings for Screenshots

- Theme: Dark (better contrast)
- Time Range: Last 1 hour or Last 6 hours
- Refresh: 10s
- Zoom: 100%

## Screenshot Organization

Organize screenshots by phase:

```
screenshots/
├── phase1-ec2/
│   └── 01-ec2-instance.png
├── phase2-cluster/
│   └── 02-minikube-status.png
├── phase3-application/
│   └── 03-application-pods.png
├── phase4-monitoring/
│   ├── 04-prometheus-pods.png
│   ├── 05-grafana-login.png
│   ├── 06-metrics-dashboard-1.png
│   └── 07-metrics-dashboard-2.png
└── phase5-logging/
    ├── 08-loki-datasource.png
    └── 09-logs-dashboard.png
```

## Embedding in Report

When adding to Markdown report:

```markdown
![Description](screenshots/filename.png)
_Caption explaining what the screenshot shows_
```

When adding to PDF:

1. Insert images with captions
2. Maintain aspect ratio
3. Use high resolution
4. Center-align for better presentation

## Final Checklist

Before submission, verify:

- [ ] All 11 required screenshots are present
- [ ] Screenshots are clear and readable
- [ ] Sensitive information is redacted
- [ ] File names follow convention
- [ ] Screenshots match the report descriptions
- [ ] All screenshots are referenced in the report

## Tips for High-Quality Screenshots

1. **Clean Environment**: Close unnecessary tabs/windows
2. **Maximize Windows**: Show full application window
3. **Good Lighting**: For phone-based screenshots
4. **No Distractions**: Hide notifications, ads
5. **Professional**: Use clean, professional appearance

---

**Note**: If you're unable to capture a specific screenshot, document the reason in your report and provide alternative evidence (logs, configuration files, etc.).

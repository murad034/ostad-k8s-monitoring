# Assignment Progress Checklist

Use this checklist to track your progress through the assignment.

---

## 📋 Pre-Deployment Checklist

- [ ] AWS account created and accessible
- [ ] Credit card/payment method added to AWS
- [ ] Downloaded SSH key (`.pem` file) and saved securely
- [ ] Project files ready in `d:\laragon\www\devops\ostad-2025\assignment\k8-monitoring`
- [ ] Read `STEP_BY_STEP.md` guide
- [ ] Terminal/PowerShell ready

---

## ☁️ Phase 1: AWS EC2 Setup

- [ ] Logged into AWS Console
- [ ] Launched EC2 instance
- [ ] Selected Ubuntu 22.04 LTS AMI
- [ ] Chose t3.medium instance type
- [ ] Created/downloaded SSH key pair
- [ ] Configured security group with all required ports:
  - [ ] SSH (22)
  - [ ] Grafana (3000)
  - [ ] Prometheus (9090)
  - [ ] Application (8080)
  - [ ] NodePort range (30000-32767)
- [ ] Set storage to 30 GiB
- [ ] Instance is in "Running" state
- [ ] **Public IP noted**: `_____________________`

**Screenshot 1**: ✅ EC2 instance running in AWS Console

---

## 🔌 Phase 2: Connect to EC2

- [ ] SSH key permissions fixed (Windows)
- [ ] Successfully connected via SSH
- [ ] Can see Ubuntu welcome message
- [ ] Terminal prompt shows: `ubuntu@ip-xxx-xxx-xxx-xxx:~$`

---

## 📦 Phase 3: Transfer Files

- [ ] Method chosen: [ ] Git Clone [ ] SCP Transfer
- [ ] Files transferred to EC2
- [ ] Can see `k8-monitoring/` folder on EC2
- [ ] All folders visible: `docs/`, `manifests/`, `scripts/`

---

## 🛠️ Phase 4: EC2 Setup

- [ ] Made scripts executable: `chmod +x scripts/*.sh`
- [ ] Ran `./scripts/01-ec2-setup.sh`
- [ ] Docker installed successfully
- [ ] kubectl installed successfully
- [ ] Helm installed successfully
- [ ] Ran `newgrp docker`
- [ ] Verified: `docker ps` works without sudo

**Versions**:

- Docker: `_______________`
- kubectl: `_______________`
- Helm: `_______________`

---

## ☸️ Phase 5: Minikube Installation

- [ ] Ran `./scripts/02-install-minikube.sh`
- [ ] Minikube installed successfully
- [ ] Cluster started successfully
- [ ] Ran `minikube status` - all components "Running"
- [ ] Ran `kubectl get nodes` - node shows "Ready"

**Screenshot 2**: ✅ `minikube status` output

---

## 🚀 Phase 6: Deploy Monitoring Stack

- [ ] Ran `./scripts/03-deploy-all.sh`
- [ ] Namespaces created
- [ ] Nginx application deployed
- [ ] Prometheus stack installed
- [ ] Loki deployed
- [ ] Promtail deployed
- [ ] Saw "Deployment Complete!" message

**Time taken**: `_____ minutes`

---

## ✅ Phase 7: Verification

- [ ] Ran `./scripts/verify.sh`
- [ ] All checks passed (0 failed)
- [ ] Cluster health: ✅
- [ ] Application pods: ✅
- [ ] Monitoring pods: ✅
- [ ] Loki pods: ✅
- [ ] Promtail pods: ✅

**Screenshot 3**: ✅ Application pods running (`kubectl get pods -n application`)
**Screenshot 4**: ✅ Monitoring pods running (`kubectl get pods -n monitoring`)

---

## 🔑 Phase 8: Get Credentials

- [ ] Retrieved Grafana password
- [ ] **Grafana Password**: `_____________________`
- [ ] Password saved securely

---

## 🌐 Phase 9: Port Forwarding

- [ ] Ran `./scripts/port-forward.sh start`
- [ ] Grafana port forward started (3000)
- [ ] Prometheus port forward started (9090)
- [ ] Terminal kept open for port forwarding

---

## 📊 Phase 10: Access Grafana

- [ ] Opened browser to `http://<EC2-IP>:3000`
- [ ] Grafana login page loaded
- [ ] Logged in successfully (admin + password)
- [ ] Grafana home dashboard visible

**Screenshot 5**: ✅ Grafana login page

### Loki Data Source Setup

- [ ] Went to Configuration → Data Sources
- [ ] Clicked "Add data source"
- [ ] Selected "Loki"
- [ ] Entered URL: `http://loki.monitoring.svc.cluster.local:3100`
- [ ] Clicked "Save & Test"
- [ ] Saw green success message

**Screenshot 6**: ✅ Loki data source configured

### View Dashboards

- [ ] Went to Dashboards → Browse
- [ ] Saw "Kubernetes Cluster Metrics - OSTAD 2025"
- [ ] Saw "Application Logs - OSTAD 2025"
- [ ] Opened metrics dashboard
- [ ] All panels showing data
- [ ] CPU/Memory gauges working
- [ ] Graphs displaying trends

**Screenshot 7**: ✅ Metrics dashboard - Part 1 (overview panels)
**Screenshot 8**: ✅ Metrics dashboard - Part 2 (graphs)

### Logs Dashboard

- [ ] Opened "Application Logs" dashboard
- [ ] Log panels showing data
- [ ] Can see real-time logs
- [ ] Error/Warning filters working

**Screenshot 9**: ✅ Logs dashboard with log streams

---

## 📸 Phase 11: Screenshots

### Required Screenshots Checklist

- [ ] **01-ec2-instance.png** - EC2 running in console
- [ ] **02-minikube-status.png** - Minikube status output
- [ ] **03-application-pods.png** - Nginx pods running
- [ ] **04-monitoring-pods.png** - All monitoring pods
- [ ] **05-grafana-login.png** - Grafana login page
- [ ] **06-metrics-dashboard-1.png** - Metrics overview
- [ ] **07-metrics-dashboard-2.png** - Metrics graphs
- [ ] **08-loki-datasource.png** - Loki configured
- [ ] **09-logs-dashboard.png** - Logs panels
- [ ] **10-prometheus-ui.png** - Prometheus UI (optional)

### Screenshot Quality Check

- [ ] All screenshots are clear and readable
- [ ] Text is visible
- [ ] No sensitive information exposed
- [ ] Screenshots properly named
- [ ] Screenshots saved in `docs/screenshots/` folder

---

## 📝 Phase 12: Report Writing

- [ ] Opened `docs/report-template.md`
- [ ] Filled in personal details:
  - [ ] Name
  - [ ] Student ID
  - [ ] Date
- [ ] Completed sections:
  - [ ] Executive Summary
  - [ ] Implementation Steps
  - [ ] Screenshots (embedded)
  - [ ] Dashboard Explanations
  - [ ] Challenges and Solutions
  - [ ] Conclusion
- [ ] Reviewed for spelling/grammar
- [ ] Converted to PDF
- [ ] PDF saved as: `Module7_K8s_Monitoring_YourName.pdf`

---

## 🧪 Testing Checklist

### Metrics Working

- [ ] Can see cluster CPU usage
- [ ] Can see cluster memory usage
- [ ] Can see pod counts
- [ ] Can see per-node metrics
- [ ] Can see per-pod metrics
- [ ] Graphs update every 10 seconds

### Logs Working

- [ ] Can see application logs
- [ ] Can filter by log level (INFO, WARN, ERROR)
- [ ] Can search logs
- [ ] New logs appear in real-time
- [ ] Can see logs per pod

### Services Accessible

- [ ] Grafana: `http://<EC2-IP>:3000` ✅
- [ ] Prometheus: `http://<EC2-IP>:9090` ✅
- [ ] Nginx app: `http://<EC2-IP>:8080` ✅ (optional)

---

## 📚 Documentation Review

- [ ] Read `README.md`
- [ ] Reviewed `QUICKSTART.md`
- [ ] Checked `TROUBLESHOOTING.md` for common issues
- [ ] Familiar with `COMMANDS.md`

---

## 🎯 Submission Checklist

### Report Requirements

- [ ] PDF report created
- [ ] All required screenshots included
- [ ] Step-by-step implementation documented
- [ ] Dashboard panels explained
- [ ] Challenges and solutions documented
- [ ] Report is 15+ pages

### Optional: GitHub Repository

- [ ] Created GitHub repository
- [ ] Pushed all configuration files
- [ ] Added README with setup instructions
- [ ] Repository URL: `_____________________`

### Final Review

- [ ] All assignment requirements met
- [ ] Report proofread
- [ ] Screenshots are high quality
- [ ] File naming is correct
- [ ] Ready for submission

---

## 🧹 Cleanup (After Submission)

- [ ] Ran `./scripts/04-cleanup.sh` on EC2
- [ ] Ran `minikube delete`
- [ ] Stopped EC2 instance (or terminated)
- [ ] Verified no charges accruing
- [ ] Backed up screenshots and report

---

## ⏱️ Time Tracking

| Phase          | Estimated    | Actual     | Notes |
| -------------- | ------------ | ---------- | ----- |
| EC2 Setup      | 15 min       | **\_**     |       |
| Connect        | 5 min        | **\_**     |       |
| File Transfer  | 10 min       | **\_**     |       |
| Environment    | 10 min       | **\_**     |       |
| Minikube       | 5 min        | **\_**     |       |
| Deployment     | 15 min       | **\_**     |       |
| Verification   | 2 min        | **\_**     |       |
| Access Grafana | 10 min       | **\_**     |       |
| Screenshots    | 10 min       | **\_**     |       |
| Report         | 30 min       | **\_**     |       |
| **Total**      | **~2 hours** | ****\_**** |       |

---

## 📊 Metrics Summary

**Your Deployment**:

- Total Nodes: `_____`
- Total Pods: `_____`
- Nginx Replicas: `_____`
- Cluster CPU Usage: `_____%`
- Cluster Memory Usage: `_____%`

**Services**:

- Grafana: Running ✅ / Not Running ❌
- Prometheus: Running ✅ / Not Running ❌
- Loki: Running ✅ / Not Running ❌
- Promtail: Running ✅ / Not Running ❌

---

## 🎓 Learning Outcomes Achieved

- [ ] Understand Kubernetes architecture
- [ ] Can deploy applications on K8s
- [ ] Understand metrics collection
- [ ] Can create Grafana dashboards
- [ ] Understand log aggregation
- [ ] Can troubleshoot K8s issues
- [ ] Understand PromQL queries
- [ ] Understand LogQL queries

---

## ⭐ Challenges Faced

Document any challenges you encountered:

1. Challenge: `_____________________`
   Solution: `_____________________`

2. Challenge: `_____________________`
   Solution: `_____________________`

3. Challenge: `_____________________`
   Solution: `_____________________`

---

## 💡 Notes & Observations

Add any additional notes or observations:

```
___________________________________________________________
___________________________________________________________
___________________________________________________________
___________________________________________________________
___________________________________________________________
```

---

## ✅ Final Status

- [ ] Assignment 100% complete
- [ ] All deliverables ready
- [ ] Report submitted
- [ ] EC2 resources cleaned up

**Completion Date**: `_____________________`

**Grade Expected**: `_____________________`

---

**Congratulations on completing the Kubernetes Monitoring & Logging Dashboard project! 🎉**

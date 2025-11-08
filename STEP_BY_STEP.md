# 🚀 Step-by-Step Deployment Guide

**IMPORTANT**: Follow these steps in order. Do not skip any step!

---

## Prerequisites Checklist

Before starting, make sure you have:

- [ ] AWS Account with access to EC2
- [ ] AWS Access Key ID and Secret Access Key (for AWS CLI - optional)
- [ ] SSH client installed on your local machine
- [ ] Basic understanding of terminal/command line

---

## Phase 1: AWS EC2 Setup (15 minutes)

### Step 1.1: Launch EC2 Instance

1. **Log in to AWS Console**: https://console.aws.amazon.com/
2. Navigate to **EC2 Dashboard**
3. Click **"Launch Instance"**

### Step 1.2: Configure Instance

**Use these exact settings**:

```
Name: k8s-monitoring-cluster
Application and OS Images (AMI): Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
Architecture: 64-bit (x86)
Instance Type: t3.medium (2 vCPU, 4 GB Memory)
```

### Step 1.3: Key Pair

- Click **"Create new key pair"**
- Name: `k8s-monitoring-key`
- Key pair type: RSA
- Private key file format: `.pem` (for Mac/Linux) or `.ppk` (for Windows with PuTTY)
- **Download and save the key file securely!**

### Step 1.4: Network Settings

Click **"Edit"** and configure:

```
VPC: default (or your preferred VPC)
Subnet: No preference
Auto-assign public IP: Enable
```

**Firewall (Security Groups)**:

- Create security group
- Security group name: `k8s-monitoring-sg`
- Description: `Security group for Kubernetes monitoring cluster`

**Inbound Security Group Rules** - Add these:

| Type       | Protocol | Port Range  | Source | Description    |
| ---------- | -------- | ----------- | ------ | -------------- |
| SSH        | TCP      | 22          | My IP  | SSH access     |
| Custom TCP | TCP      | 3000        | My IP  | Grafana        |
| Custom TCP | TCP      | 9090        | My IP  | Prometheus     |
| Custom TCP | TCP      | 8080        | My IP  | Application    |
| Custom TCP | TCP      | 30000-32767 | My IP  | NodePort range |

### Step 1.5: Storage

```
Volume 1 (Root):
- Size: 30 GiB
- Volume Type: gp3
- Delete on Termination: Yes
```

### Step 1.6: Launch

1. Review all settings
2. Click **"Launch Instance"**
3. Wait for instance state to become **"Running"** (2-3 minutes)
4. **Note down the Public IPv4 address**

Example: `54.123.456.789` (yours will be different)

---

## Phase 2: Connect to EC2 (5 minutes)

### Step 2.1: Prepare SSH Key (Windows)

Open PowerShell and run:

```powershell
# Navigate to where you downloaded the key
cd ~\Downloads

# If you get a permission error, you may need to adjust file permissions
icacls k8s-monitoring-key.pem /inheritance:r
icacls k8s-monitoring-key.pem /grant:r "%USERNAME%:R"
```

### Step 2.2: Connect via SSH

**Replace `<EC2-PUBLIC-IP>` with your actual EC2 IP address!**

```powershell
ssh -i "k8s-monitoring-key.pem" ubuntu@<EC2-PUBLIC-IP>
```

Example:

```powershell
ssh -i "k8s-monitoring-key.pem" ubuntu@54.123.456.789
```

**First time connecting?** Type `yes` when asked about authenticity.

You should see:

```
Welcome to Ubuntu 22.04 LTS
ubuntu@ip-xxx-xxx-xxx-xxx:~$
```

✅ **You're now connected to your EC2 instance!**

---

## Phase 3: Transfer Project Files to EC2 (10 minutes)

### Option A: Using Git (Recommended if you have GitHub)

**On EC2 instance**:

```bash
# Install git
sudo apt update
sudo apt install -y git

# Clone your repository (if you've uploaded to GitHub)
git clone <your-repo-url>
cd k8-monitoring
```

### Option B: Using SCP (From Your Local Machine)

**On your local PowerShell** (new window, keep SSH session open):

```powershell
# Navigate to project directory
cd d:\laragon\www\devops\ostad-2025\assignment

# Copy entire project to EC2
scp -i "~\Downloads\k8s-monitoring-key.pem" -r k8-monitoring ubuntu@<EC2-PUBLIC-IP>:~/
```

This will take 1-2 minutes.

**Back on EC2**, verify files:

```bash
cd ~/k8-monitoring
ls -la
```

You should see:

```
docs/
manifests/
scripts/
README.md
...
```

---

## Phase 4: EC2 Environment Setup (10 minutes)

**On EC2 instance**:

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run EC2 setup script
./scripts/01-ec2-setup.sh
```

This will install:

- ✅ Docker
- ✅ kubectl
- ✅ Helm
- ✅ System dependencies

**Wait for completion** (~5-10 minutes)

### Important: Apply Docker Group

```bash
# After setup completes, run:
newgrp docker

# Verify Docker works without sudo
docker ps
```

Should show empty container list (not permission error).

---

## Phase 5: Install Minikube (5 minutes)

**On EC2 instance**:

```bash
# Run Minikube installation script
./scripts/02-install-minikube.sh
```

This will:

- ✅ Install Minikube
- ✅ Start Kubernetes cluster
- ✅ Enable required addons

**Wait for completion** (~5 minutes)

### Verify Cluster is Running

```bash
# Check Minikube status
minikube status
```

Should show:

```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

```bash
# Check nodes
kubectl get nodes
```

Should show:

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.x.x
```

✅ **Kubernetes cluster is ready!**

---

## Phase 6: Deploy Monitoring Stack (15 minutes)

**On EC2 instance**:

```bash
# Deploy everything
./scripts/03-deploy-all.sh
```

This will deploy:

1. ✅ Namespaces (application, monitoring)
2. ✅ Nginx application (3 replicas)
3. ✅ Prometheus & Grafana (Helm chart)
4. ✅ Loki (log storage)
5. ✅ Promtail (log collection)
6. ✅ Grafana dashboards

**This takes 10-15 minutes** - be patient!

You'll see lots of output. Wait for:

```
============================================
Deployment Complete!
============================================
```

---

## Phase 7: Verify Deployment (2 minutes)

**On EC2 instance**:

```bash
# Run verification script
./scripts/verify.sh
```

This checks:

- ✅ Cluster health
- ✅ All pods running
- ✅ Services accessible
- ✅ Connectivity

**Expected output**:

```
Passed: 20+
Failed: 0
✓ All checks passed!
```

If any checks fail, check `docs/TROUBLESHOOTING.md`

---

## Phase 8: Get Grafana Password (1 minute)

**On EC2 instance**:

```bash
# Get Grafana admin password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

**Copy this password!** You'll need it to login.

Example output: `prom-operator` (yours will be different)

---

## Phase 9: Start Port Forwarding (2 minutes)

**On EC2 instance**:

```bash
# Start port forwards for Grafana and Prometheus
./scripts/port-forward.sh start
```

Output:

```
[INFO] Starting Grafana port forward...
[INFO] Grafana is now accessible at http://<EC2-IP>:3000
[INFO] Starting Prometheus port forward...
[INFO] Prometheus is now accessible at http://<EC2-IP>:9090
```

### Keep This Terminal Open!

Port forwarding needs to stay running. Open a **new SSH session** if you need to run more commands.

---

## Phase 10: Access Grafana (5 minutes)

### Step 10.1: Open Browser

On your **local computer**, open a web browser and go to:

```
http://<EC2-PUBLIC-IP>:3000
```

Example: `http://54.123.456.789:3000`

### Step 10.2: Login to Grafana

```
Username: admin
Password: <password from Phase 8>
```

### Step 10.3: Add Loki Data Source

1. Click **Configuration** (⚙️ icon) → **Data Sources**
2. Click **"Add data source"**
3. Select **"Loki"**
4. Configure:
   ```
   Name: Loki
   URL: http://loki.monitoring.svc.cluster.local:3100
   ```
5. Click **"Save & Test"**
6. Should show: ✅ "Data source connected and labels found"

### Step 10.4: View Dashboards

1. Click **Dashboards** (four squares icon) → **Browse**
2. You should see:

   - Kubernetes Cluster Metrics - OSTAD 2025
   - Application Logs - OSTAD 2025
   - Plus pre-loaded Prometheus dashboards

3. Click **"Kubernetes Cluster Metrics - OSTAD 2025"**

You should see:

- ✅ Total Nodes: 1
- ✅ Total Pods: 10+
- ✅ CPU Usage graph
- ✅ Memory Usage graph
- ✅ All panels showing data

---

## Phase 11: Take Screenshots (10 minutes)

Follow the checklist in `docs/screenshots/README.md`

### Required Screenshots:

1. **EC2 Instance** (AWS Console)

   - Show instance running with public IP

2. **Minikube Status** (Terminal)

   ```bash
   minikube status
   ```

3. **Application Pods** (Terminal)

   ```bash
   kubectl get pods -n application
   ```

4. **Monitoring Pods** (Terminal)

   ```bash
   kubectl get pods -n monitoring
   ```

5. **Grafana Login Page** (Browser)

6. **Grafana Metrics Dashboard** (Browser)

   - Full dashboard view showing all panels

7. **Loki Data Source** (Browser)

   - Configuration page showing "connected"

8. **Grafana Logs Dashboard** (Browser)
   - Show log panels with data

Save all screenshots in `docs/screenshots/` folder.

---

## Phase 12: Write Report (30 minutes)

Use the template: `docs/report-template.md`

1. Open `docs/report-template.md`
2. Fill in your details:
   - Your name
   - Student ID
   - Date
3. Complete each section:
   - Add your screenshots
   - Document challenges you faced
   - Explain your solutions
4. Convert to PDF for submission

---

## Summary: What You've Built

✅ **Infrastructure**: AWS EC2 with Minikube  
✅ **Application**: Nginx with 3 replicas  
✅ **Monitoring**: Prometheus collecting metrics  
✅ **Visualization**: Grafana with 11 metric panels  
✅ **Logging**: Loki aggregating logs  
✅ **Collection**: Promtail on all nodes  
✅ **Dashboards**: 2 custom dashboards

---

## Useful Commands

### Check Everything

```bash
# All pods
kubectl get pods -A

# Verify stack
./scripts/verify.sh

# Port forward status
./scripts/port-forward.sh status
```

### Access Services

```bash
# Grafana: http://<EC2-IP>:3000
# Prometheus: http://<EC2-IP>:9090
```

### Restart Port Forwards

```bash
./scripts/port-forward.sh restart
```

### View Logs

```bash
# Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -f

# Application logs
kubectl logs -n application -l app=nginx -f
```

---

## Cleanup (When Done)

**On EC2**:

```bash
# Delete all resources
./scripts/04-cleanup.sh

# Delete Minikube cluster
minikube delete
```

**On AWS Console**:

- Terminate EC2 instance
- Delete security group (if no longer needed)

---

## Troubleshooting

### Port 3000 Not Accessible

```bash
# Check port forward is running
ps aux | grep port-forward

# Restart
./scripts/port-forward.sh restart

# Check EC2 security group allows port 3000
```

### Pods Not Running

```bash
# Check pod status
kubectl get pods -A

# Describe failing pod
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>
```

### No Data in Grafana

```bash
# Check Prometheus is scraping
# Open: http://<EC2-IP>:9090/targets

# All targets should be "UP"
```

For more issues, see: `docs/TROUBLESHOOTING.md`

---

## Need Help?

1. Check `docs/TROUBLESHOOTING.md`
2. Check `docs/COMMANDS.md`
3. Review logs: `kubectl logs <pod> -n <namespace>`
4. Run verification: `./scripts/verify.sh`

---

## Estimated Timeline

| Phase     | Time         | Description          |
| --------- | ------------ | -------------------- |
| 1         | 15 min       | Launch EC2           |
| 2         | 5 min        | Connect to EC2       |
| 3         | 10 min       | Transfer files       |
| 4         | 10 min       | Setup environment    |
| 5         | 5 min        | Install Minikube     |
| 6         | 15 min       | Deploy stack         |
| 7         | 2 min        | Verify               |
| 8-10      | 10 min       | Access Grafana       |
| 11        | 10 min       | Screenshots          |
| 12        | 30 min       | Report               |
| **Total** | **~2 hours** | **Complete project** |

---

## Success Criteria

✅ Minikube cluster running  
✅ All pods in Running state  
✅ Grafana accessible on port 3000  
✅ Dashboards showing real data  
✅ Loki receiving logs  
✅ Screenshots captured  
✅ Report completed

---

**You're ready to start! Begin with Phase 1.**

**Questions? Check the documentation or run `./scripts/verify.sh` to diagnose issues.**

🚀 **Good luck with your assignment!**

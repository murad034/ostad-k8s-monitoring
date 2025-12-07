# 🔧 Fixing Stability and Connection Issues

## 🔴 Problems You're Experiencing

1. **kubectl timeouts**: "TLS handshake timeout"
2. **Port-forward breaking**: "broken pipe", "lost connection to pod"
3. **Grafana data sources disappearing**: Prometheus and Loki need to be re-added
4. **Connection resets**: Frequent disconnections

## 🎯 Root Causes

### 1. Minikube Resource Issues
- EC2 instance only has 4GB RAM
- Minikube + Docker + all pods = high memory usage
- System becomes unstable under load

### 2. Port-Forward Instability
- `kubectl port-forward` is meant for debugging, not production
- Breaks on network issues, pod restarts, or timeouts
- Not suitable for long-running connections

### 3. Grafana Losing Configuration
- Grafana stores data sources in memory/ephemeral storage
- Pod restarts = configuration loss
- No persistent volume configured

## ✅ Solutions Implemented

### 1. Auto-Configured Grafana Data Sources
**Before**: Manual configuration every time
**After**: ConfigMap automatically loads Prometheus and Loki

The updated script now:
```bash
# Creates persistent ConfigMap
kubectl create configmap grafana-datasources -n monitoring

# Grafana auto-loads data sources from /etc/grafana/provisioning/datasources
```

### 2. Better Port Forwarding Options
**Option A (Most Stable)**: Minikube Tunnel
```bash
sudo minikube tunnel
# Access via NodePort - no port-forward needed
```

**Option B (Auto-Restart)**: Stable Port Forward Script
```bash
./scripts/stable-port-forward.sh grafana-simple monitoring 3000 3000
# Automatically restarts on failure
```

**Option C (Background)**: Start All Services
```bash
./scripts/start-port-forwards.sh
# Runs both Grafana and Backend in background
```

## 🚀 How to Use Updated Scripts

### Step 1: Upload Updated Files to EC2
```bash
# On your local machine (Windows PowerShell)
scp -i ~/.ssh/my-account-pem-key.pem -r e:/Development/Server/laragon/www/devops/ostad-2025/ostad-k8s-monitoring/* ubuntu@44.223.43.143:~/ostad-k8s-monitoring/
```

### Step 2: Run Main Deployment Script
```bash
# On EC2
cd ~/ostad-k8s-monitoring
chmod +x scripts/*.sh
./scripts/deploy-esim-no-changes.sh
```

**This will:**
- ✅ Deploy Loki, Promtail (Minikube version), Grafana
- ✅ Auto-configure Prometheus and Loki data sources
- ✅ Use NodePort for Grafana (more stable than port-forward)
- ✅ Verify log collection

### Step 3: Access Services

**Option 1 - Minikube Tunnel (RECOMMENDED)**
```bash
# Terminal 1 - Start tunnel (keep running)
sudo minikube tunnel

# Access:
# Grafana: http://44.223.43.143:<NodePort>
# Get NodePort: kubectl get svc grafana-simple -n monitoring
```

**Option 2 - Auto-Restart Port Forward**
```bash
# Terminal 1 - Grafana
./scripts/stable-port-forward.sh grafana-simple monitoring 3000 3000

# Terminal 2 - Backend
./scripts/stable-port-forward.sh esim-backend esim 3001 3000

# Access:
# Grafana: http://44.223.43.143:3000
# Backend: http://44.223.43.143:3001
```

**Option 3 - Background Port Forwards**
```bash
# Start both in background
./scripts/start-port-forwards.sh

# Check status
tail -f /tmp/grafana-pf.log
tail -f /tmp/backend-pf.log

# Stop all
pkill -f 'kubectl port-forward'
```

## 🔧 When Things Go Wrong

### Issue: kubectl commands timeout
```bash
# Check Minikube
minikube status

# If not running
minikube stop
minikube start --driver=docker --memory=3072 --cpus=2

# If still issues - check Docker
docker ps
sudo systemctl restart docker
```

### Issue: Grafana data sources disappeared
```bash
# Run stability fix
./scripts/fix-stability.sh

# This will:
# - Restart Grafana
# - Recreate ConfigMap if missing
# - Data sources will auto-reload
```

### Issue: Port-forward keeps breaking
```bash
# Don't use kubectl port-forward directly
# Use one of these instead:

# Option A: Minikube tunnel
sudo minikube tunnel

# Option B: Auto-restart script
./scripts/stable-port-forward.sh grafana-simple monitoring 3000 3000

# Option C: Background script
./scripts/start-port-forwards.sh
```

### Issue: Loki not showing logs
```bash
# Restart Promtail
kubectl delete pod -n monitoring -l app=promtail

# Wait 30 seconds, then check
kubectl exec -n monitoring loki-0 -- wget -qO- 'http://localhost:3100/loki/api/v1/label/namespace/values' | grep esim
```

### Issue: Everything is slow/unstable
```bash
# Check system resources
free -h
docker system df

# Clean up if needed
docker system prune -f

# Restart Minikube with fresh state
minikube delete
minikube start --driver=docker --memory=3072 --cpus=2

# Redeploy
./scripts/deploy-esim-no-changes.sh
```

## 📋 Quick Reference Commands

```bash
# Deploy everything
./scripts/deploy-esim-no-changes.sh

# Fix stability issues
./scripts/fix-stability.sh

# Start port forwards
./scripts/start-port-forwards.sh

# Stop port forwards
pkill -f 'kubectl port-forward'

# Check pod status
kubectl get pods -A

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring

# Restart backend
kubectl rollout restart deployment/esim-backend -n esim

# View logs
kubectl logs -n esim -l app=esim-backend -f
kubectl logs -n monitoring -l app=grafana -f

# Access Grafana (if Minikube tunnel running)
kubectl get svc grafana-simple -n monitoring
# Then: http://YOUR_EC2_IP:<NodePort>
```

## ⚡ Performance Tips

### 1. Increase EC2 Resources
Current: c7i-flex.large (4GB RAM)
Recommended: t3.medium (4GB RAM) or t3.large (8GB RAM)

### 2. Reduce Minikube Resource Usage
```bash
# Current
minikube start --memory=3072 --cpus=2

# If still unstable, reduce replicas
kubectl scale deployment grafana -n monitoring --replicas=1
kubectl scale deployment esim-backend -n esim --replicas=1
```

### 3. Use Persistent Volumes
Consider adding persistent storage for Grafana:
```yaml
volumeMounts:
  - name: grafana-storage
    mountPath: /var/lib/grafana
volumes:
  - name: grafana-storage
    persistentVolumeClaim:
      claimName: grafana-pvc
```

## 🎯 Expected Behavior After Fix

✅ Grafana data sources **persist** after restart
✅ Port forwards **auto-restart** on failure  
✅ Loki logs **continuously collected**  
✅ kubectl commands **don't timeout**  
✅ Connections **stay stable**  

## 📞 Still Having Issues?

If problems continue:

1. **Check EC2 instance health**
   ```bash
   top
   free -h
   df -h
   ```

2. **Check Docker health**
   ```bash
   docker info
   docker system df
   ```

3. **Full reset**
   ```bash
   minikube delete
   docker system prune -a -f
   minikube start --driver=docker --memory=3072 --cpus=2
   ./scripts/deploy-esim-no-changes.sh
   ```

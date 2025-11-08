# Troubleshooting Guide

Common issues and their solutions when setting up the Kubernetes Monitoring & Logging Dashboard.

## Table of Contents

1. [EC2 and System Issues](#ec2-and-system-issues)
2. [Minikube Issues](#minikube-issues)
3. [Application Deployment Issues](#application-deployment-issues)
4. [Prometheus Issues](#prometheus-issues)
5. [Grafana Issues](#grafana-issues)
6. [Loki and Promtail Issues](#loki-and-promtail-issues)
7. [Networking Issues](#networking-issues)
8. [Resource Issues](#resource-issues)

---

## EC2 and System Issues

### Issue: Cannot SSH to EC2 Instance

**Symptoms:**

```
Connection timed out
Permission denied (publickey)
```

**Solutions:**

1. **Check Security Group**:

   - Ensure SSH (port 22) is open for your IP
   - Verify the source IP matches your current IP

2. **Verify Key Permissions**:

   ```bash
   chmod 400 your-key.pem
   ```

3. **Check Instance State**:

   - Ensure instance is in "running" state
   - Verify instance has a public IP

4. **Correct SSH Command**:
   ```bash
   ssh -i "your-key.pem" ubuntu@<PUBLIC-IP>
   ```

### Issue: Docker Permission Denied

**Symptoms:**

```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution:**

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes
newgrp docker

# Verify
docker ps
```

### Issue: Insufficient Disk Space

**Symptoms:**

```
No space left on device
```

**Solution:**

```bash
# Check disk usage
df -h

# Clean Docker images and containers
docker system prune -a

# Clean apt cache
sudo apt clean
sudo apt autoremove
```

---

## Minikube Issues

### Issue: Minikube Won't Start

**Symptoms:**

```
Exiting due to GUEST_PROVISION: error provisioning guest
minikube start failed
```

**Solutions:**

1. **Delete and Restart**:

   ```bash
   minikube delete
   minikube start --driver=docker --memory=4096 --cpus=2
   ```

2. **Check Docker**:

   ```bash
   docker ps  # Verify Docker is running
   sudo systemctl status docker
   ```

3. **Increase Resources**:

   ```bash
   minikube start --driver=docker --memory=6144 --cpus=2 --disk-size=30g
   ```

4. **Check Logs**:
   ```bash
   minikube logs
   ```

### Issue: Minikube Stuck on Starting

**Symptoms:**

```
Waiting for cluster to come online...
```

**Solution:**

```bash
# Stop and restart with verbose output
minikube delete
minikube start --driver=docker --memory=4096 --cpus=2 --v=7

# Check events
kubectl get events -A
```

### Issue: Kubectl Connection Refused

**Symptoms:**

```
The connection to the server localhost:8080 was refused
```

**Solution:**

```bash
# Verify Minikube is running
minikube status

# Update kubeconfig
minikube update-context

# Verify connection
kubectl cluster-info
```

---

## Application Deployment Issues

### Issue: Pods Stuck in Pending

**Symptoms:**

```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-xxxxx-xxxxx        0/1     Pending   0          2m
```

**Diagnosis:**

```bash
# Describe the pod
kubectl describe pod <pod-name> -n application

# Check events
kubectl get events -n application --sort-by='.lastTimestamp'
```

**Common Causes:**

1. **Insufficient Resources**:

   ```bash
   # Check node resources
   kubectl top nodes
   kubectl describe nodes

   # Solution: Reduce resource requests or increase cluster resources
   ```

2. **Image Pull Errors**:

   ```bash
   # Check if image exists
   kubectl describe pod <pod-name> -n application | grep -i image

   # Solution: Verify image name and registry
   ```

### Issue: Pods CrashLoopBackOff

**Symptoms:**

```
NAME                                READY   STATUS             RESTARTS   AGE
nginx-deployment-xxxxx-xxxxx        0/1     CrashLoopBackOff   5          3m
```

**Diagnosis:**

```bash
# Check pod logs
kubectl logs <pod-name> -n application

# Check previous logs
kubectl logs <pod-name> -n application --previous

# Describe pod
kubectl describe pod <pod-name> -n application
```

**Solutions:**

1. **Configuration Error**:

   - Check ConfigMap and Secret mounts
   - Verify environment variables

2. **Resource Limits**:

   - Increase memory/CPU limits
   - Check for OOMKilled status

3. **Health Check Failures**:
   ```yaml
   # Adjust probe settings
   livenessProbe:
     initialDelaySeconds: 30 # Increase delay
     periodSeconds: 10
   ```

### Issue: Service Not Accessible

**Symptoms:**

```
curl: (7) Failed to connect to <IP> port 30080: Connection refused
```

**Diagnosis:**

```bash
# Check service
kubectl get svc -n application

# Check endpoints
kubectl get endpoints -n application

# Verify pods are running
kubectl get pods -n application
```

**Solution:**

```bash
# Check NodePort
kubectl describe svc nginx-service -n application

# Test from inside cluster
kubectl run test --rm -it --image=busybox -- wget -O- nginx-service.application.svc.cluster.local
```

---

## Prometheus Issues

### Issue: Helm Install Timeout

**Symptoms:**

```
Error: timed out waiting for the condition
```

**Solutions:**

1. **Increase Timeout**:

   ```bash
   helm install prometheus prometheus-community/kube-prometheus-stack \
     -n monitoring \
     --create-namespace \
     -f manifests/prometheus/values.yaml \
     --timeout 15m
   ```

2. **Check Pod Status**:

   ```bash
   kubectl get pods -n monitoring
   kubectl describe pod <pod-name> -n monitoring
   ```

3. **Check Image Pull**:
   ```bash
   kubectl get events -n monitoring | grep -i pull
   ```

### Issue: Prometheus Not Scraping Metrics

**Symptoms:**

- No data in Grafana dashboards
- Targets showing as "down" in Prometheus UI

**Diagnosis:**

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

**Solutions:**

1. **Verify ServiceMonitor**:

   ```bash
   kubectl get servicemonitor -n application
   kubectl describe servicemonitor nginx-metrics -n application
   ```

2. **Check Service Labels**:

   ```bash
   kubectl get svc -n application --show-labels
   ```

3. **Verify Prometheus RBAC**:
   ```bash
   kubectl get clusterrole | grep prometheus
   kubectl get clusterrolebinding | grep prometheus
   ```

### Issue: Prometheus High Memory Usage

**Symptoms:**

- Prometheus pod restarting
- OOMKilled status

**Solution:**

```yaml
# Increase memory in values.yaml
prometheus:
  prometheusSpec:
    resources:
      limits:
        memory: 2Gi
      requests:
        memory: 1Gi
```

---

## Grafana Issues

### Issue: Cannot Access Grafana UI

**Symptoms:**

```
Connection refused
ERR_CONNECTION_REFUSED
```

**Solutions:**

1. **Verify Pod is Running**:

   ```bash
   kubectl get pods -n monitoring | grep grafana
   ```

2. **Check Port Forward**:

   ```bash
   # Kill existing port forwards
   pkill -f "port-forward.*grafana"

   # Start new port forward
   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'
   ```

3. **Check Security Group**:

   - Ensure port 3000 is open in EC2 security group

4. **Check Service**:
   ```bash
   kubectl describe svc prometheus-grafana -n monitoring
   ```

### Issue: Wrong Grafana Password

**Symptoms:**

- Login fails with correct username

**Solution:**

```bash
# Retrieve password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Reset password
kubectl delete secret -n monitoring prometheus-grafana
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set grafana.adminPassword=newpassword
```

### Issue: Grafana Dashboard Shows No Data

**Symptoms:**

- Panels show "No Data"
- "N/A" in stat panels

**Diagnosis:**

```bash
# Check Prometheus data source
# In Grafana: Configuration → Data Sources → Prometheus → Save & Test

# Verify Prometheus is accessible
kubectl run test -n monitoring --rm -it --image=busybox -- \
  wget -O- prometheus-kube-prometheus-prometheus:9090/api/v1/query?query=up
```

**Solutions:**

1. **Fix Data Source URL**:

   - Use: `http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`

2. **Adjust Time Range**:

   - Ensure time range includes available data
   - Check "Last 1 hour" or "Last 6 hours"

3. **Verify Metrics Exist**:

   ```bash
   # Port forward Prometheus
   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

   # Visit http://localhost:9090 and test query
   ```

### Issue: Dashboard Import Fails

**Symptoms:**

```
Dashboard import failed
Invalid JSON
```

**Solution:**

```bash
# Validate JSON
cat dashboards/k8s-cluster-metrics.json | jq .

# Import via kubectl instead
kubectl apply -f manifests/grafana/dashboard-metrics.yaml

# Restart Grafana
kubectl rollout restart deployment prometheus-grafana -n monitoring
```

---

## Loki and Promtail Issues

### Issue: Loki Pod Not Starting

**Symptoms:**

```
loki-0   0/1     CrashLoopBackOff   5          3m
```

**Diagnosis:**

```bash
# Check logs
kubectl logs -n monitoring loki-0

# Check events
kubectl describe pod -n monitoring loki-0
```

**Common Solutions:**

1. **PVC Issues**:

   ```bash
   # Check PVC
   kubectl get pvc -n monitoring

   # Check storage class
   kubectl get storageclass
   ```

2. **Config Issues**:

   ```bash
   # Verify ConfigMap
   kubectl get cm -n monitoring loki-config -o yaml
   ```

3. **Port Conflicts**:
   - Check if port 3100 is already in use

### Issue: Promtail Not Collecting Logs

**Symptoms:**

- No logs in Loki/Grafana
- Promtail running but no data

**Diagnosis:**

```bash
# Check Promtail logs
kubectl logs -n monitoring -l app=promtail

# Check Promtail targets
# Look for "error" or "failed" messages
```

**Solutions:**

1. **Fix Loki URL**:

   ```yaml
   # In promtail config
   clients:
     - url: http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push
   ```

2. **Check RBAC**:

   ```bash
   kubectl get clusterrole promtail
   kubectl get clusterrolebinding promtail
   ```

3. **Verify Log Path**:
   ```bash
   # Check if logs exist on node
   minikube ssh
   ls /var/log/pods/
   ```

### Issue: Loki Data Source Not Working in Grafana

**Symptoms:**

- "Data source connected, but no labels received"
- Red indicator in data source settings

**Solutions:**

1. **Verify Loki Service**:

   ```bash
   kubectl get svc -n monitoring loki
   kubectl run test -n monitoring --rm -it --image=curlimages/curl -- \
     curl http://loki.monitoring.svc.cluster.local:3100/ready
   ```

2. **Correct Data Source URL**:

   - URL: `http://loki.monitoring.svc.cluster.local:3100`
   - Access: Server (proxy)

3. **Check Loki Logs**:
   ```bash
   kubectl logs -n monitoring loki-0
   ```

### Issue: No Logs for Specific Namespace

**Symptoms:**

- Logs from other namespaces visible
- Application namespace logs missing

**Solution:**

```bash
# Verify Promtail is scraping the namespace
kubectl logs -n monitoring -l app=promtail | grep -i application

# Check if pods exist
kubectl get pods -n application

# Test LogQL query
# In Grafana Explore: {namespace="application"}
```

---

## Networking Issues

### Issue: Service DNS Not Resolving

**Symptoms:**

```
nslookup: can't resolve 'loki.monitoring.svc.cluster.local'
```

**Solution:**

```bash
# Check CoreDNS
kubectl get pods -n kube-system | grep coredns

# Restart CoreDNS
kubectl rollout restart deployment coredns -n kube-system

# Test DNS
kubectl run test --rm -it --image=busybox -- nslookup kubernetes.default
```

### Issue: NodePort Not Accessible

**Symptoms:**

- Cannot access service via NodePort

**Solution:**

```bash
# Get Minikube IP
minikube ip

# Get NodePort
kubectl get svc -n application nginx-service

# Access via Minikube IP
curl http://$(minikube ip):30080

# For EC2, use:
curl http://<EC2-PUBLIC-IP>:30080
```

### Issue: Port Forward Connection Reset

**Symptoms:**

```
error: lost connection to pod
```

**Solutions:**

1. **Use Background Process**:

   ```bash
   nohup kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0' > /tmp/grafana-pf.log 2>&1 &
   ```

2. **Use Screen/Tmux**:

   ```bash
   screen -S grafana
   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'
   # Ctrl+A, D to detach
   ```

3. **Check Pod Health**:
   ```bash
   kubectl get pods -n monitoring -w
   ```

---

## Resource Issues

### Issue: Insufficient CPU

**Symptoms:**

```
0/1 nodes are available: 1 Insufficient cpu
```

**Solutions:**

1. **Reduce Resource Requests**:

   ```yaml
   resources:
     requests:
       cpu: 50m # Reduce from 100m
       memory: 128Mi
   ```

2. **Increase Minikube Resources**:

   ```bash
   minikube delete
   minikube start --cpus=4 --memory=8192
   ```

3. **Check Resource Usage**:
   ```bash
   kubectl top nodes
   kubectl top pods -A
   ```

### Issue: Insufficient Memory

**Symptoms:**

```
0/1 nodes are available: 1 Insufficient memory
OOMKilled
```

**Solutions:**

1. **Increase Node Memory**:

   ```bash
   minikube delete
   minikube start --memory=8192
   ```

2. **Reduce Pod Memory**:

   ```yaml
   resources:
     limits:
       memory: 256Mi # Reduce from 512Mi
   ```

3. **Enable Swap (Not Recommended for Production)**:
   ```bash
   sudo swapon -a
   ```

### Issue: Disk Pressure

**Symptoms:**

```
node.kubernetes.io/disk-pressure
```

**Solution:**

```bash
# Clean up Docker
docker system prune -af

# Increase disk size
minikube delete
minikube start --disk-size=40g

# Check disk usage
kubectl describe node
```

---

## General Debugging Commands

```bash
# Pod debugging
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Events
kubectl get events -A --sort-by='.lastTimestamp'
kubectl get events -n <namespace> --field-selector type=Warning

# Resource usage
kubectl top nodes
kubectl top pods -A

# Configuration
kubectl get cm -n <namespace>
kubectl get secrets -n <namespace>

# Services and networking
kubectl get svc -A
kubectl get endpoints -A
kubectl describe svc <service-name> -n <namespace>

# Helm
helm list -A
helm status <release> -n <namespace>
helm get values <release> -n <namespace>

# Logs collection for support
kubectl logs -n monitoring <pod-name> > pod.log
kubectl describe pod -n monitoring <pod-name> > pod-describe.txt
kubectl get events -A --sort-by='.lastTimestamp' > events.txt
```

---

## Getting Help

If issues persist:

1. **Check Logs**: Always start with pod logs and events
2. **Google the Error**: Search exact error messages
3. **Documentation**: Refer to official docs
4. **GitHub Issues**: Check project GitHub for similar issues
5. **Community**: Ask on Kubernetes Slack, Stack Overflow

**Useful Resources:**

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [Prometheus Troubleshooting](https://prometheus.io/docs/prometheus/latest/troubleshooting/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Troubleshooting](https://grafana.com/docs/loki/latest/operations/troubleshooting/)

---

**Remember**: When in doubt, check the logs! 🔍

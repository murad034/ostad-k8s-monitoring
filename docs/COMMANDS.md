# Commands Cheat Sheet

Quick reference for all commonly used commands in this project.

## AWS EC2 Commands

### SSH Connection

```bash
# Connect to EC2
ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>

# Copy files to EC2
scp -i "your-key.pem" -r ./k8-monitoring ubuntu@<EC2-PUBLIC-IP>:~/

# Copy files from EC2
scp -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>:~/file.txt ./
```

### EC2 Instance Management (AWS CLI)

```bash
# List instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output table

# Start instance
aws ec2 start-instances --instance-ids i-xxxxxxxxx

# Stop instance
aws ec2 stop-instances --instance-ids i-xxxxxxxxx

# Terminate instance
aws ec2 terminate-instances --instance-ids i-xxxxxxxxx
```

## System Commands

### Package Management

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install package
sudo apt install <package-name>

# Remove package
sudo apt remove <package-name>

# Clean cache
sudo apt clean && sudo apt autoremove
```

### Docker Commands

```bash
# Check Docker version
docker --version

# List containers
docker ps -a

# List images
docker images

# Remove unused resources
docker system prune -a

# Check Docker service
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker
```

### System Resources

```bash
# Check memory
free -h

# Check disk space
df -h

# Check CPU
top
htop

# Check processes
ps aux | grep <process-name>

# Kill process
kill <PID>
pkill <process-name>
```

## Minikube Commands

### Basic Operations

```bash
# Start Minikube
minikube start

# Start with specific resources
minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=20g

# Stop Minikube
minikube stop

# Delete cluster
minikube delete

# Status
minikube status

# Get cluster IP
minikube ip

# SSH into node
minikube ssh
```

### Addons

```bash
# List addons
minikube addons list

# Enable addon
minikube addons enable <addon-name>

# Disable addon
minikube addons disable <addon-name>

# Common addons
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable ingress
```

### Dashboard

```bash
# Open dashboard
minikube dashboard

# Get dashboard URL
minikube dashboard --url
```

## Kubectl Commands

### Cluster Information

```bash
# Cluster info
kubectl cluster-info

# Cluster info detailed
kubectl cluster-info dump

# Get nodes
kubectl get nodes

# Describe node
kubectl describe node <node-name>

# Get Kubernetes version
kubectl version
```

### Namespace Operations

```bash
# List namespaces
kubectl get namespaces
kubectl get ns

# Create namespace
kubectl create namespace <namespace-name>

# Delete namespace
kubectl delete namespace <namespace-name>

# Set default namespace
kubectl config set-context --current --namespace=<namespace-name>
```

### Pod Operations

```bash
# List all pods
kubectl get pods -A

# List pods in namespace
kubectl get pods -n <namespace>

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Get pod logs
kubectl logs <pod-name> -n <namespace>

# Follow logs
kubectl logs -f <pod-name> -n <namespace>

# Previous logs (for crashed containers)
kubectl logs <pod-name> -n <namespace> --previous

# Execute command in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash
kubectl exec -it <pod-name> -n <namespace> -- sh

# Delete pod
kubectl delete pod <pod-name> -n <namespace>

# Watch pods
kubectl get pods -n <namespace> -w
```

### Deployment Operations

```bash
# List deployments
kubectl get deployments -n <namespace>

# Describe deployment
kubectl describe deployment <deployment-name> -n <namespace>

# Scale deployment
kubectl scale deployment <deployment-name> -n <namespace> --replicas=5

# Update image
kubectl set image deployment/<deployment-name> <container-name>=<new-image> -n <namespace>

# Rollout status
kubectl rollout status deployment/<deployment-name> -n <namespace>

# Rollout history
kubectl rollout history deployment/<deployment-name> -n <namespace>

# Rollback
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Restart deployment
kubectl rollout restart deployment/<deployment-name> -n <namespace>

# Delete deployment
kubectl delete deployment <deployment-name> -n <namespace>
```

### Service Operations

```bash
# List services
kubectl get svc -A

# List services in namespace
kubectl get svc -n <namespace>

# Describe service
kubectl describe svc <service-name> -n <namespace>

# Get endpoints
kubectl get endpoints -n <namespace>

# Delete service
kubectl delete svc <service-name> -n <namespace>
```

### ConfigMap and Secrets

```bash
# List ConfigMaps
kubectl get configmaps -n <namespace>
kubectl get cm -n <namespace>

# Describe ConfigMap
kubectl describe cm <configmap-name> -n <namespace>

# Get ConfigMap YAML
kubectl get cm <configmap-name> -n <namespace> -o yaml

# List Secrets
kubectl get secrets -n <namespace>

# Describe Secret
kubectl describe secret <secret-name> -n <namespace>

# Get Secret value
kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.<key>}' | base64 --decode
```

### Resource Management

```bash
# Apply configuration
kubectl apply -f <file.yaml>
kubectl apply -f <directory>/

# Delete resources
kubectl delete -f <file.yaml>

# Get all resources
kubectl get all -n <namespace>

# Get resource YAML
kubectl get <resource-type> <resource-name> -n <namespace> -o yaml

# Edit resource
kubectl edit <resource-type> <resource-name> -n <namespace>
```

### Events and Troubleshooting

```bash
# Get events
kubectl get events -A

# Get events in namespace
kubectl get events -n <namespace>

# Sort events by time
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Filter events
kubectl get events -n <namespace> --field-selector type=Warning

# Check resource usage
kubectl top nodes
kubectl top pods -A
kubectl top pods -n <namespace>
```

### Port Forwarding

```bash
# Forward port
kubectl port-forward <pod-name> <local-port>:<pod-port> -n <namespace>

# Forward service port
kubectl port-forward svc/<service-name> <local-port>:<service-port> -n <namespace>

# Forward with specific address
kubectl port-forward svc/<service-name> <local-port>:<service-port> -n <namespace> --address='0.0.0.0'

# Background port forward
nohup kubectl port-forward svc/<service-name> <local-port>:<service-port> -n <namespace> --address='0.0.0.0' &
```

### Labels and Selectors

```bash
# Get resources with labels
kubectl get pods -n <namespace> --show-labels

# Filter by label
kubectl get pods -n <namespace> -l app=nginx

# Add label
kubectl label pod <pod-name> -n <namespace> key=value

# Remove label
kubectl label pod <pod-name> -n <namespace> key-
```

## Helm Commands

### Repository Management

```bash
# Add repository
helm repo add <repo-name> <repo-url>

# Update repositories
helm repo update

# List repositories
helm repo list

# Remove repository
helm repo remove <repo-name>

# Search charts
helm search repo <keyword>
```

### Chart Operations

```bash
# Install chart
helm install <release-name> <chart-name> -n <namespace>

# Install with values file
helm install <release-name> <chart-name> -n <namespace> -f values.yaml

# Install with set values
helm install <release-name> <chart-name> -n <namespace> --set key=value

# Upgrade release
helm upgrade <release-name> <chart-name> -n <namespace>

# Uninstall release
helm uninstall <release-name> -n <namespace>

# List releases
helm list -A

# Get release status
helm status <release-name> -n <namespace>

# Get release values
helm get values <release-name> -n <namespace>

# Get release manifest
helm get manifest <release-name> -n <namespace>

# Rollback release
helm rollback <release-name> <revision> -n <namespace>

# Show chart values
helm show values <chart-name>
```

## Project-Specific Commands

### Setup

```bash
# Run EC2 setup
./scripts/01-ec2-setup.sh

# Install Minikube
./scripts/02-install-minikube.sh

# Deploy all components
./scripts/03-deploy-all.sh

# Cleanup
./scripts/04-cleanup.sh
```

### Grafana

```bash
# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0'

# Restart Grafana
kubectl rollout restart deployment prometheus-grafana -n monitoring

# Check Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -f
```

### Prometheus

```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 --address='0.0.0.0'

# Check Prometheus logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus -f

# Restart Prometheus
kubectl rollout restart statefulset prometheus-prometheus-kube-prometheus-prometheus -n monitoring
```

### Loki

```bash
# Check Loki logs
kubectl logs -n monitoring -l app=loki -f

# Restart Loki
kubectl rollout restart statefulset loki -n monitoring

# Test Loki
kubectl run test -n monitoring --rm -it --image=curlimages/curl -- \
  curl http://loki.monitoring.svc.cluster.local:3100/ready
```

### Promtail

```bash
# Check Promtail logs
kubectl logs -n monitoring -l app=promtail -f

# Restart Promtail
kubectl rollout restart daemonset promtail -n monitoring

# Check Promtail on specific node
kubectl logs -n monitoring promtail-<pod-suffix>
```

### Application

```bash
# Get application pods
kubectl get pods -n application

# Access application
kubectl port-forward -n application svc/nginx-service 8080:80 --address='0.0.0.0'

# Check application logs
kubectl logs -n application -l app=nginx -f

# Restart application
kubectl rollout restart deployment nginx-deployment -n application

# Scale application
kubectl scale deployment nginx-deployment -n application --replicas=5
```

## Monitoring Queries

### PromQL Examples

```promql
# CPU Usage
rate(container_cpu_usage_seconds_total[5m])

# Memory Usage
container_memory_working_set_bytes

# Pod Count
count(kube_pod_info)

# Node CPU
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Node Memory
node_memory_MemTotal_bytes - node_memory_MemFree_bytes
```

### LogQL Examples

```logql
# All logs from namespace
{namespace="application"}

# Error logs
{namespace="application"} |= "error"

# Logs by pod
{namespace="application", pod="nginx-deployment-xxxxx"}

# Log rate
rate({namespace="application"}[5m])

# Filtered logs
{namespace="application"} | json | level="ERROR"
```

## Troubleshooting Commands

### Pod Debugging

```bash
# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Get logs
kubectl logs <pod-name> -n <namespace>

# Get previous logs
kubectl logs <pod-name> -n <namespace> --previous

# Execute into pod
kubectl exec -it <pod-name> -n <namespace> -- sh

# Check container status
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.status.containerStatuses[*].state}'
```

### Network Debugging

```bash
# Test DNS
kubectl run test --rm -it --image=busybox -- nslookup kubernetes.default

# Test service connectivity
kubectl run test --rm -it --image=curlimages/curl -- curl http://<service>.<namespace>.svc.cluster.local:<port>

# Check endpoints
kubectl get endpoints -n <namespace>
```

### Resource Debugging

```bash
# Check node resources
kubectl describe node <node-name>

# Top commands
kubectl top nodes
kubectl top pods -A

# Check events
kubectl get events -A --sort-by='.lastTimestamp'
```

## Quick Aliases (Add to ~/.bashrc)

```bash
# Kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgs='kubectl get svc'
alias kgsa='kubectl get svc -A'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'

# Namespace shortcuts
alias kapp='kubectl -n application'
alias kmon='kubectl -n monitoring'

# Common operations
alias kga='kubectl get all'
alias kaa='kubectl apply -f'
alias kda='kubectl delete -f'

# Minikube
alias mk='minikube'
alias mks='minikube status'
alias mkstart='minikube start'
alias mkstop='minikube stop'
```

---

**Pro Tip**: Use `kubectl --help` or `helm --help` for more commands and options!

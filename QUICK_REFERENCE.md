# 🎯 Quick Reference Card

**Print this page and keep it handy during deployment!**

---

## 📌 Essential Information

### Your EC2 Details

```
Public IP: ___.___.___.___
SSH Key: k8s-monitoring-key.pem
Username: ubuntu
Instance Type: t3.medium
Region: _____________
```

### Grafana Credentials

```
URL: http://<EC2-IP>:3000
Username: admin
Password: ___________________
```

---

## 🚀 Quick Commands

### Connect to EC2

```bash
ssh -i "k8s-monitoring-key.pem" ubuntu@<EC2-IP>
```

### Deploy Stack (One Command!)

```bash
cd ~/k8-monitoring
chmod +x scripts/*.sh
./scripts/01-ec2-setup.sh && \
newgrp docker && \
./scripts/02-install-minikube.sh && \
./scripts/03-deploy-all.sh
```

### Get Grafana Password

```bash
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

### Start Port Forwarding

```bash
./scripts/port-forward.sh start
```

### Verify Everything

```bash
./scripts/verify.sh
```

---

## 🔗 Access URLs

| Service    | URL                    | Port |
| ---------- | ---------------------- | ---- |
| Grafana    | `http://<EC2-IP>:3000` | 3000 |
| Prometheus | `http://<EC2-IP>:9090` | 9090 |
| Nginx App  | `http://<EC2-IP>:8080` | 8080 |

---

## 📊 Loki Data Source Config

```
Name: Loki
Type: Loki
URL: http://loki.monitoring.svc.cluster.local:3100
Access: Server (proxy)
```

---

## 🐛 Quick Troubleshooting

### Pods not running?

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

### Can't access Grafana?

```bash
# Check port forward
ps aux | grep port-forward

# Restart
./scripts/port-forward.sh restart

# Check security group allows port 3000
```

### No data in dashboards?

```bash
# Check Prometheus targets
# Open: http://<EC2-IP>:9090/targets
# All should be "UP"

# Adjust time range in Grafana to "Last 6 hours"
```

---

## 📸 Screenshot Checklist

- [ ] 1. EC2 instance running (AWS Console)
- [ ] 2. Minikube status (Terminal)
- [ ] 3. Application pods (Terminal)
- [ ] 4. Monitoring pods (Terminal)
- [ ] 5. Grafana login (Browser)
- [ ] 6. Loki data source (Browser)
- [ ] 7. Metrics dashboard (Browser)
- [ ] 8. Logs dashboard (Browser)

---

## ⚡ Emergency Commands

### Restart Everything

```bash
minikube stop
minikube start
./scripts/port-forward.sh restart
```

### Check Resources

```bash
kubectl top nodes
kubectl top pods -A
```

### View Logs

```bash
# Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Prometheus
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Loki
kubectl logs -n monitoring -l app=loki

# Application
kubectl logs -n application -l app=nginx
```

---

## 📝 Important Files

| File                      | Purpose                   |
| ------------------------- | ------------------------- |
| `STEP_BY_STEP.md`         | Detailed deployment guide |
| `CHECKLIST.md`            | Track your progress       |
| `docs/TROUBLESHOOTING.md` | Problem solutions         |
| `docs/COMMANDS.md`        | Command reference         |
| `docs/report-template.md` | Report template           |

---

## ⏱️ Estimated Timeline

| Task              | Time         |
| ----------------- | ------------ |
| EC2 Setup         | 15 min       |
| File Transfer     | 10 min       |
| Environment Setup | 10 min       |
| Minikube Install  | 5 min        |
| Deploy Stack      | 15 min       |
| Verify & Access   | 10 min       |
| Screenshots       | 10 min       |
| Report Writing    | 30 min       |
| **TOTAL**         | **~2 hours** |

---

## 🎯 Success Indicators

✅ `minikube status` shows all "Running"  
✅ `kubectl get pods -A` shows all "Running"  
✅ Can access Grafana at port 3000  
✅ Dashboards show real data  
✅ Loki connected and receiving logs

---

## 📞 Help Resources

1. Check `TROUBLESHOOTING.md`
2. Run `./scripts/verify.sh`
3. Check pod logs
4. Review security group rules
5. Verify port forwarding is running

---

## 🔐 Security Group Rules

| Type       | Port        | Source |
| ---------- | ----------- | ------ |
| SSH        | 22          | My IP  |
| Custom TCP | 3000        | My IP  |
| Custom TCP | 9090        | My IP  |
| Custom TCP | 8080        | My IP  |
| Custom TCP | 30000-32767 | My IP  |

---

## 📋 Pre-Deployment Checklist

- [ ] AWS account ready
- [ ] SSH key downloaded
- [ ] Project files ready
- [ ] Read STEP_BY_STEP.md
- [ ] Terminal ready

---

## 🎓 Submission Requirements

- [ ] PDF Report (15+ pages)
- [ ] 8+ Screenshots
- [ ] All sections complete
- [ ] GitHub repo (optional)

---

**Keep this card handy during your deployment!**

**Good luck! 🚀**

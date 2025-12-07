# Fixing Grafana Loki Query Errors

## ❌ Error You're Seeing:

```
Error: parse error : queries require at least one regexp or equality matcher 
that does not have an empty-compatible value. for instance, app=~".*" does not 
meet this requirement, but app=~".+" will
```

## 🔴 What This Means:

Loki requires at least one **specific label matcher** in queries. You cannot use wildcard-only patterns like `{app=~".*"}` because they match everything including empty values.

## ✅ CORRECT Queries:

### ✓ Good - Specific namespace
```
{namespace="esim"}
```

### ✓ Good - Specific app
```
{app="esim-backend"}
```

### ✓ Good - Multiple labels
```
{namespace="esim", app="esim-backend"}
```

### ✓ Good - With log filtering
```
{namespace="esim"} |= "error"
{namespace="esim"} |~ "ERROR|error|Error"
```

### ✓ Good - Non-empty regex
```
{namespace="esim", app=~".+"}
```

## ❌ WRONG Queries:

### ✗ Bad - Empty-compatible wildcard
```
{app=~".*"}
```

### ✗ Bad - No specific matcher
```
{namespace=~".*"}
```

### ✗ Bad - All wildcards
```
{app=~".*", namespace=~".*"}
```

## 🔧 How to Use Loki in Grafana:

### Step 1: Open Grafana Explore
1. Go to: http://YOUR_EC2_IP:3000
2. Click "Explore" (compass icon on left)
3. Select "Loki" from dropdown

### Step 2: Run Query
**Start with this simple query:**
```
{namespace="esim"}
```

### Step 3: Filter Logs
**Add filters after the query:**
```
{namespace="esim"} |= "GET"              # Contains "GET"
{namespace="esim"} |~ "ERROR|error"      # Matches error pattern
{namespace="esim"} != "healthcheck"      # Excludes healthcheck
```

### Step 4: Extract Fields
**Parse JSON logs:**
```
{namespace="esim"} | json | level="error"
```

## 📊 Common Queries for eSIM Backend:

### All backend logs
```
{namespace="esim", app="esim-backend"}
```

### Only error logs
```
{namespace="esim"} |~ "(?i)error"
```

### API requests
```
{namespace="esim"} |~ "GET|POST|PUT|DELETE"
```

### Database queries
```
{namespace="esim"} |~ "query|SELECT|INSERT|UPDATE"
```

### Last hour only
```
{namespace="esim"} [1h]
```

### Count logs
```
count_over_time({namespace="esim"}[5m])
```

## 🎯 Quick Fix Commands (Run on EC2):

### 1. Check if logs exist in Loki
```bash
./scripts/diagnose-loki.sh
```

### 2. Force log collection
```bash
./scripts/force-loki-collection.sh
```

### 3. Manually verify
```bash
kubectl exec -n monitoring loki-0 -- wget -qO- \
  'http://localhost:3100/loki/api/v1/label/namespace/values'
```

Should show: `["esim","monitoring","kube-system"...]`

## 🔍 If Still No Logs:

### Check 1: Is backend running?
```bash
kubectl get pods -n esim
```

### Check 2: Is Promtail collecting?
```bash
kubectl logs -n monitoring -l app=promtail --tail=50 | grep esim
```

### Check 3: Generate test logs
```bash
# Port forward backend first
kubectl port-forward -n esim svc/esim-backend 3001:3000 --address='0.0.0.0' &

# Make requests
for i in {1..10}; do curl http://localhost:3001/api/esim/plans; done

# Wait and check
sleep 30
./scripts/diagnose-loki.sh
```

### Check 4: Restart Promtail
```bash
kubectl delete pod -n monitoring -l app=promtail
kubectl wait --for=condition=ready pod -l app=promtail -n monitoring --timeout=60s
```

## 📝 Expected Results:

After running `./scripts/force-loki-collection.sh`:

```
✅ SUCCESS! Loki is now receiving logs from esim namespace!

Namespaces in Loki:
esim
monitoring
kube-system
default

Now you can query in Grafana Explore:
  {namespace="esim"}
  {namespace="esim", app="esim-backend"}
```

Then in Grafana, you should see actual log lines!

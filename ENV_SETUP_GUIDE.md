# How to Extract Environment Variables from Docker Compose

## Step 1: Check your docker-compose-local.yml

Look for the `environment:` section in your docker-compose file.

Example:
```yaml
services:
  esim-backend:
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/esim
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=your-secret
      - API_KEY=your-key
```

## Step 2: Create Kubernetes Secret

Create a file: `manifests/application/esim-secrets.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: esim-backend-secrets
  namespace: esim
type: Opaque
stringData:
  # Replace with YOUR actual values from docker-compose
  DATABASE_URL: "postgresql://user:pass@host:5432/esim"
  JWT_SECRET: "your-jwt-secret"
  API_KEY: "your-api-key"
  REDIS_URL: "redis://host:6379"
```

## Step 3: Update ConfigMap

Edit `esim-backend-no-changes.yaml` and add more environment variables:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: esim-backend-config
  namespace: esim
data:
  NODE_ENV: "production"
  PORT: "3000"
  # Add your non-sensitive config here
  LOG_LEVEL: "info"
  APP_NAME: "esim-backend"
```

## Step 4: Apply the Secret

```bash
# On EC2
kubectl apply -f manifests/application/esim-secrets.yaml
```

## Step 5: Redeploy

```bash
kubectl delete namespace esim
kubectl apply -f manifests/application/esim-backend-no-changes.yaml
kubectl apply -f manifests/application/esim-secrets.yaml
```

## Step 6: Verify Environment Variables

```bash
# Check if env vars are loaded
kubectl exec -n esim -it $(kubectl get pod -n esim -l app=esim-backend -o name) -- env | grep DATABASE
```

---

## Quick Fix for Database Connection

If your database is on your LOCAL machine or another server:

**Option A: Database is on EC2**
- Change `DATABASE_URL` to use EC2 internal IP or `localhost`

**Option B: Database is external**
- Use the external database URL
- Make sure EC2 security group allows outbound connections

**Option C: Database is in Docker on EC2**
- Deploy database to Kubernetes too
- Or use `host.docker.internal` or EC2 IP

---

## Example: Complete Secret File

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: esim-backend-secrets
  namespace: esim
type: Opaque
stringData:
  # Database (REPLACE WITH YOUR VALUES)
  DATABASE_URL: "postgresql://postgres:password@YOUR_DB_HOST:5432/esim_db"
  
  # JWT
  JWT_SECRET: "your-very-secret-jwt-key"
  
  # API Keys
  API_KEY: "your-api-key"
  STRIPE_KEY: "your-stripe-key"
  
  # Redis
  REDIS_URL: "redis://YOUR_REDIS_HOST:6379"
  
  # Other secrets
  ENCRYPTION_KEY: "your-encryption-key"
```

**SHARE YOUR docker-compose-local.yml** and I'll create the exact Secret file for you!

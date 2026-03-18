# 🚀 Quick Deploy Guide

## Problem: ImagePullBackOff Error

The deployment is failing because the container image `ghcr.io/nebulapay/payment-api:latest` doesn't exist in the registry yet.

---

## Solution 1: Build and Push to GHCR (Recommended)

### Prerequisites
- Docker installed and running
- GitHub account with container registry access

### Steps

```bash
# 1. Login to GitHub Container Registry
export CR_PAT=YOUR_GITHUB_TOKEN
echo $CR_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# 2. Build and push the image
cd /Users/owolabiyusuff/nebulapay-ops
make build-image-push

# 3. Deploy to Kubernetes
make deploy-staging
```

**Or use the automated script:**
```bash
./scripts/deploy.sh staging
```

---

## Solution 2: Use AWS ECR (Alternative)

### Prerequisites
- AWS CLI configured
- ECR repository created

### Steps

```bash
# 1. Create ECR repository (one-time)
aws ecr create-repository --repository-name nebulapay/payment-api

# 2. Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 564268554451.dkr.ecr.us-east-1.amazonaws.com

# 3. Update deployment to use ECR image
# Edit infra/kubernetes/staging/deployment.yaml
# Change image to: 564268554451.dkr.ecr.us-east-1.amazonaws.com/nebulapay/payment-api:latest

# 4. Build and push
docker build -f docker/Dockerfile -t 564268554451.dkr.ecr.us-east-1.amazonaws.com/nebulapay/payment-api:latest .
docker push 564268554451.dkr.ecr.us-east-1.amazonaws.com/nebulapay/payment-api:latest

# 5. Deploy
make deploy-staging
```

---

## Solution 3: Skip Image Pull (Local Testing Only)

For local testing with kind/minikube:

```bash
# Build image locally
docker build -f docker/Dockerfile -t nebulapay-payment-api:local .

# Load into kind cluster
kind load docker-image nebulapay-payment-api:local --name kind

# Update deployment to use local image
# Edit infra/kubernetes/staging/deployment.yaml
# Change image to: nebulapay-payment-api:local

# Deploy
kubectl apply -f infra/kubernetes/staging/
```

---

## Verify Deployment

```bash
# Check pod status
kubectl get pods -n staging

# Watch rollout status
kubectl rollout status deployment/nebulapay-payment-api -n staging

# View logs
kubectl logs -f deployment/nebulapay-payment-api -n staging

# Port forward to test
kubectl port-forward svc/payment-api 3000:80 -n staging

# Test API
curl http://localhost:3000/health/live
```

---

## Common Issues

### ImagePullBackOff

**Cause:** Image doesn't exist in registry or credentials issue

**Fix:**
```bash
# Check image exists
docker pull ghcr.io/nebulapay/payment-api:latest

# If using private registry, ensure secret exists
kubectl get secret regcred -n staging

# Create image pull secret if needed
kubectl create secret docker-registry regcred \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN \
  -n staging
```

### ErrImageNeverPull

**Cause:** Image pull policy issue

**Fix:** Ensure `imagePullPolicy: Always` is set in deployment

### Container Creating → CrashLoopBackOff

**Cause:** Application error or missing configuration

**Fix:**
```bash
# Check logs
kubectl logs <pod-name> -n staging

# Check environment variables
kubectl describe pod <pod-name> -n staging

# Verify secrets exist
kubectl get secrets -n staging
```

---

## Full Deployment Checklist

- [ ] Terraform infrastructure deployed
- [ ] EKS cluster running
- [ ] kubectl configured (`make kube-config`)
- [ ] Docker image built and pushed
- [ ] Namespace created (`kubectl create namespace staging`)
- [ ] Secrets created (DB and Redis credentials)
- [ ] Deployment applied
- [ ] Pods running (`kubectl get pods -n staging`)
- [ ] Service accessible
- [ ] Health checks passing

---

## Quick Commands Reference

| Command | Description |
|---------|-------------|
| `make build-image-push` | Build and push Docker image |
| `make deploy-staging` | Deploy to staging |
| `./scripts/deploy.sh staging` | Automated build and deploy |
| `kubectl get pods -n staging` | Check pod status |
| `kubectl logs -f deployment/nebulapay-payment-api -n staging` | View logs |
| `kubectl port-forward svc/payment-api 3000:80 -n staging` | Port forward API |

---

**Next:** Run `./scripts/deploy.sh staging` for automated deployment!
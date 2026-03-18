# NebulaPay-OPS - Deployment Guide

## Prerequisites

Before deploying to Kubernetes, ensure you have:

1. ✅ AWS CLI configured (`aws configure`)
2. ✅ kubectl installed
3. ✅ Terraform infrastructure deployed
4. ✅ EKS cluster running
5. ✅ IAM permissions for EKS access

---

## Step-by-Step Deployment

### Step 1: Deploy AWS Infrastructure with Terraform

```bash
cd /Users/owolabiyusuff/nebulapay-ops/infra/terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan -out=tfplan

# Apply infrastructure (this takes 15-20 minutes)
terraform apply tfplan
```

**Expected Output:**
```
Apply complete! Resources: 45 added, 0 changed, 0 destroyed.

Outputs:

eks_cluster_name = "nebulapay-eks"
eks_cluster_endpoint = "https://..."
vpc_id = "vpc-..."
```

### Step 2: Configure kubectl to Connect to EKS

```bash
cd /Users/owolabiyusuff/nebulapay-ops

# Configure kubectl (using Makefile)
make kube-config

# Or manually:
aws eks update-kubeconfig --name nebulapay-eks --region us-east-1
```

**Expected Output:**
```
Added new context arn:aws:eks:us-east-1:123456789:cluster/nebulapay-eks to /Users/owolabiyusuff/.kube/config
```

### Step 3: Verify Cluster Connection

```bash
# Check cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes

# Expected output:
# NAME                                STATUS   ROLES    AGE   VERSION
# ip-10-0-1-10.ec2.internal          Ready    <none>   5m    v1.29.0
# ip-10-0-1-20.ec2.internal          Ready    <none>   5m    v1.29.0
```

### Step 4: Deploy to Staging

```bash
# Using Makefile
make deploy-staging

# Or manually:
kubectl apply -f infra/kubernetes/staging/

# Watch deployment rollout
kubectl rollout status deployment/nebulapay-payment-api -n staging --timeout=300s
```

**Expected Output:**
```
namespace/staging created
serviceaccount/payment-api created
deployment.apps/nebulapay-payment-api created
service/payment-api created
horizontalpodautoscaler.autoscaling/nebulapay-payment-api created
networkpolicy.networking.k8s.io/payment-api-network-policy created
deployment "nebulapay-payment-api" successfully rolled out
```

### Step 5: Verify Deployment

```bash
# Check pods are running
kubectl get pods -n staging

# Expected output:
# NAME                                     READY   STATUS    RESTARTS   AGE
# nebulapay-payment-api-6d8f9c7b5-x2k4m   1/1     Running   0          2m
# nebulapay-payment-api-6d8f9c7b5-p9n3l   1/1     Running   0          2m

# Check services
kubectl get svc -n staging

# Check logs
kubectl logs -f deployment/nebulapay-payment-api -n staging
```

### Step 6: Test the API

```bash
# Port forward to access the API locally
kubectl port-forward svc/payment-api 3000:80 -n staging

# In another terminal, test the health endpoint
curl http://localhost:3000/health/live

# Test the API root
curl http://localhost:3000/

# Create a payment
curl -X POST http://localhost:3000/api/v1/payments \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.50,
    "currency": "USD",
    "payerId": "customer_001",
    "payeeId": "merchant_001",
    "description": "Test payment"
  }'
```

### Step 7: Deploy to Production (Optional)

```bash
# Using Makefile (requires manual confirmation)
make deploy-production

# Or manually:
kubectl apply -f infra/kubernetes/production/
kubectl rollout status deployment/nebulapay-payment-api -n production --timeout=600s
```

---

## Troubleshooting

### Issue: "Not connected to Kubernetes cluster"

**Solution:**
```bash
# Run the kube-config target
make kube-config

# Or manually update kubeconfig
aws eks update-kubeconfig --name nebulapay-eks --region us-east-1
```

### Issue: "kubectl command not found"

**Solution:**
```bash
# Install kubectl (macOS)
brew install kubectl

# Install kubectl (Linux)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Issue: "Unauthorized" or "Forbidden" errors

**Solution:**
```bash
# Ensure you have the correct IAM role assumed
aws sts get-caller-identity

# Re-run the kubeconfig update
aws eks update-kubeconfig --name nebulapay-eks --region us-east-1
```

### Issue: Pods stuck in "Pending" state

**Solution:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n staging

# Check node availability
kubectl get nodes
kubectl describe nodes

# Check resource quotas
kubectl get resourcequota -n staging
```

### Issue: Pods in "CrashLoopBackOff"

**Solution:**
```bash
# Check logs
kubectl logs <pod-name> -n staging --previous

# Check environment variables and secrets
kubectl describe pod <pod-name> -n staging

# Verify database connectivity
kubectl exec -it <pod-name> -n staging -- env | grep DB
```

---

## Rollback Deployment

If something goes wrong:

```bash
# Rollback to previous revision
kubectl rollout undo deployment/nebulapay-payment-api -n staging

# Rollback to specific revision
kubectl rollout undo deployment/nebulapay-payment-api -n staging --to-revision=2

# Check rollout history
kubectl rollout history deployment/nebulapay-payment-api -n staging
```

---

## Clean Up

To avoid AWS charges, clean up resources when done:

```bash
# Delete Kubernetes resources
kubectl delete -f infra/kubernetes/staging/
kubectl delete -f infra/kubernetes/production/

# Delete Terraform infrastructure
cd infra/terraform
terraform destroy

# Remove kubeconfig context
kubectl config delete-context arn:aws:eks:us-east-1:123456789:cluster/nebulapay-eks
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `make kube-config` | Configure kubectl for EKS |
| `make deploy-staging` | Deploy to staging environment |
| `make deploy-production` | Deploy to production (with approval) |
| `make logs` | View staging logs |
| `make logs-prod` | View production logs |
| `make port-forward` | Port forward to staging API |
| `kubectl get pods -n staging` | Check staging pods |
| `kubectl rollout status deploy/<name> -n staging` | Check deployment status |

---

## Next Steps

After successful deployment:

1. **Set up monitoring**: Configure Prometheus and Grafana
2. **Configure alerts**: Set up CloudWatch alarms
3. **Enable logging**: Centralize logs with CloudWatch or ELK
4. **Set up SSL/TLS**: Configure HTTPS with AWS Certificate Manager
5. **Configure domain**: Set up DNS with Route53
6. **Implement CI/CD**: Connect GitHub Actions pipeline

---

**🎉 Deployment Complete!** Your NebulaPay payment API is now running on AWS EKS.
# CI/CD Pipeline Troubleshooting Guide

## Issue: "Some specified paths were not resolved, unable to cache dependencies"

### Root Cause
The `actions/setup-node@v4` action was trying to cache dependencies but couldn't resolve the path `apps/payment-api/package-lock.json` because the cache lookup happens **before** the working directory is set.

### Solution Applied

**Before (❌ Broken):**
```yaml
- name: 🟢 Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'
    cache-dependency-path: apps/payment-api/package-lock.json  # This fails!

- name: 📦 Install dependencies
  working-directory: apps/payment-api  # Too late for cache
  run: npm ci
```

**After (✅ Fixed):**
```yaml
defaults:
  run:
    working-directory: apps/payment-api  # Applied to ALL run steps

- name: 🟢 Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'  # Simple cache, no path specified

- name: 📦 Install dependencies
  run: npm ci  # Automatically in correct directory
```

### Key Changes

1. **Removed `cache-dependency-path`** - This caused path resolution errors
2. **Added `defaults.run.working-directory`** - Applies to all `run` steps in the job
3. **Simplified cache configuration** - Just `cache: 'npm'` without specific path
4. **Added debug output** - Shows directory structure and package files

### How It Works Now

1. ✅ Checkout code to runner workspace
2. ✅ `defaults` sets working directory for all `run` commands
3. ✅ Node.js setup caches npm packages (no path conflicts)
4. ✅ All npm commands run in `apps/payment-api/` automatically
5. ✅ Cache works without explicit path resolution

---

## Pipeline Structure

```
Stage 1: Lint & Security Scan (continue-on-error: true)
  ├─ Checkout code
  ├─ Debug: Show directory structure
  ├─ Setup Node.js + cache
  ├─ Install dependencies
  ├─ Run linter
  ├─ Run security audit
  └─ Run type check

Stage 2: Automated Testing (continue-on-error: true)
  ├─ Checkout code
  ├─ Debug: Show directory
  ├─ Setup Node.js + cache
  ├─ Install dependencies
  ├─ Run tests
  └─ Tests complete

Stage 3: Build & Push to ECR (requires AWS_ECR_PASSWORD secret)
  ├─ Checkout code
  ├─ Login to ECR
  ├─ Set image tag
  ├─ Setup Docker Buildx
  ├─ Build and push container
  └─ Build complete

Stage 4: Deploy to Staging
  ├─ Checkout code
  ├─ Setup kubectl
  ├─ Update deployment image
  ├─ Apply Kubernetes manifests
  ├─ Health check
  └─ Deployment complete
```

---

## Required Secrets

### For ECR Push (Stage 3)

1. **Get ECR password:**
   ```bash
   ssh -i your-key.pem ubuntu@YOUR_EC2_IP
   aws ecr get-login-password --region us-east-1
   ```

2. **Add to GitHub:**
   - Go to: https://github.com/417buddy/NebulaPay-OPS/settings/secrets/actions/new
   - Name: `AWS_ECR_PASSWORD`
   - Value: (paste output from step 1)

### For Kubernetes Deploy (Stage 4)

The runner uses the EC2 instance's IAM role for AWS authentication. Ensure the IAM role has:
- `eks:DescribeCluster`
- `eks:AccessKubernetesApi`
- `ecr:GetAuthorizationCode`

---

## Common Issues & Solutions

### Issue 1: "Runner offline"
**Solution:** 
```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
cd /home/ubuntu/actions-runner
sudo ./svc.sh start
```

### Issue 2: "Permission denied" with Docker
**Solution:**
```bash
sudo usermod -aG docker ubuntu
# Log out and log back in
```

### Issue 3: npm cache errors
**Solution:** Already fixed in latest commit. Re-run workflow.

### Issue 4: ECR login fails
**Solution:** Add `AWS_ECR_PASSWORD` secret (see above)

### Issue 5: Kubernetes deploy fails
**Solution:** Ensure EC2 IAM role has EKS access and kubeconfig is set up

---

## How to Trigger Pipeline

### Automatic (on push to main/develop):
```bash
git push origin main
```

### Manual (via GitHub UI):
1. Go to: https://github.com/417buddy/NebulaPay-OPS/actions
2. Click "CI/CD Pipeline - Simplified"
3. Click "Run workflow"
4. Select branch: `main`
5. Click "Run workflow"

---

## Monitoring Pipeline

### View Logs:
1. Go to: https://github.com/417buddy/NebulaPay-OPS/actions
2. Click on running workflow
3. Click on individual job (e.g., "Lint & Security Scan")
4. See real-time logs

### View Runner Logs (on EC2):
```bash
sudo journalctl -u actions.runner.417buddy.NebulaPay-OPS.ec2-runner-1 -f
```

### Check Runner Status:
```bash
cd /home/ubuntu/actions-runner
sudo ./svc.sh status
```

---

## Pipeline Status Indicators

| Status | Meaning | Action |
|--------|---------|--------|
| ✅ Success | All stages passed | Nothing needed |
| ⚠️ Warning | Some steps had warnings (continue-on-error) | Review logs |
| ❌ Failed | Critical stage failed | Check error logs |
| 🟡 In Progress | Pipeline running | Wait or monitor logs |
| ⏪ Cancelled | Manually cancelled | Re-run if needed |

---

## Next Steps After Pipeline Success

1. ✅ Verify ECR image pushed:
   ```bash
   aws ecr list-images --repository-name nebulapay/payment-api --region us-east-1
   ```

2. ✅ Check Kubernetes deployment:
   ```bash
   kubectl get pods -n staging
   kubectl get svc -n staging
   ```

3. ✅ Test API endpoint:
   ```bash
   curl http://YOUR_LB_URL/health/live
   ```

---

## Contact & Support

- **GitHub Issues:** https://github.com/417buddy/NebulaPay-OPS/issues
- **EC2 Runner Logs:** `sudo journalctl -u actions.runner.* -f`
- **Pipeline Logs:** GitHub Actions tab

---

**Last Updated:** March 23, 2026  
**Pipeline Version:** 2.0 (Simplified with error handling)

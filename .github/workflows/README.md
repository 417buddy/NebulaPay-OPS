# NebulaPay CI/CD Workflows

## 📁 Workflow Files

| File | Purpose | When to Use |
|------|---------|-------------|
| `ci-cd.yml` | **Production pipeline** | Main CI/CD for all deployments |
| `simple-cicd-test.yml` | Testing/debugging | Test new features before production |
| `ultra-simple-cicd.yml` | Basic verification | Quick runner connectivity test |

---

## 🚀 CI/CD Pipeline (ci-cd.yml)

### **Triggers:**
- Push to `main` or `develop`
- Pull requests to `main` or `develop`
- Manual trigger via GitHub Actions UI

### **Stages:**

```
1. Setup
   ├─ Checkout code
   ├─ Setup Node.js 20
   ├─ Setup Docker Buildx
   └─ Setup kubectl

2. Install & Lint
   ├─ npm install
   ├─ npm run lint
   ├─ npm audit
   └─ npm run typecheck

3. Tests
   └─ npm test (--testPathPattern=health)

4. Build & Push to ECR (main only)
   ├─ Login to ECR
   ├─ Build Docker image
   └─ Push with SHA + latest tags

5. Deploy to Staging (main only)
   ├─ Update Kubernetes manifest
   ├─ Apply manifests
   └─ Wait for rollout
```

### **Required Secrets:**

| Secret | Description | How to Get |
|--------|-------------|------------|
| `AWS_ECR_PASSWORD` | ECR authentication | `aws ecr get-login-password --region us-east-1` |

### **How to Run:**

**Automatic:**
```bash
git push origin main
```

**Manual:**
1. Go to: https://github.com/417buddy/NebulaPay-OPS/actions/workflows/ci-cd.yml
2. Click "Run workflow"
3. Select branch
4. Click "Run workflow"

---

## 🧪 Test Workflows

### **simple-cicd-test.yml**
- Quick test of CI/CD steps
- No deployment
- Good for testing changes

### **ultra-simple-cicd.yml**
- Basic connectivity test
- 6 simple steps
- Verifies runner is working

---

## 🏗️ Architecture

**Single-Job Architecture:**
- All steps run in one job
- No `needs:` dependencies (causes failures)
- Uses `if:` conditionals for branch-specific steps
- Runs on self-hosted EC2 runner

---

## 📊 Expected Duration

| Stage | Duration |
|-------|----------|
| Setup | 1-2 min |
| Install & Lint | 3-5 min |
| Tests | 2-3 min |
| Build & Push | 5-10 min |
| Deploy | 5-10 min |
| **Total** | **15-30 min** |

---

## 🔧 Troubleshooting

### **Pipeline Fails Immediately:**
1. Check runner status: https://github.com/417buddy/NebulaPay-OPS/settings/actions/runners
2. Verify `AWS_ECR_PASSWORD` secret is set
3. Check EC2 instance is running

### **Build Fails:**
1. Check Docker is working on runner
2. Verify ECR repository exists
3. Check ECR password is valid

### **Deploy Fails:**
1. Check EKS cluster access
2. Verify kubeconfig is configured
3. Check staging namespace exists

---

## 📝 Pipeline Status

| Branch | Status | Last Run |
|--------|--------|----------|
| `main` | ✅ Ready | - |
| `develop` | ✅ Ready | - |

---

**Last Updated:** March 23, 2026  
**Pipeline Version:** 4.0 (Clean Single-Job)

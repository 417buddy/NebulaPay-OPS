# NebulaPay-OPS - Complete DevOps Walkthrough

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Getting Started](#getting-started)
4. [CI/CD Pipeline](#cicd-pipeline)
5. [EC2 Self-Hosted Runner](#ec2-self-hosted-runner)
6. [Infrastructure as Code](#infrastructure-as-code)
7. [Deployment Guide](#deployment-guide)
8. [Monitoring & Observability](#monitoring--observability)
9. [Troubleshooting](#troubleshooting)

---

## Project Overview

**NebulaPay-OPS** is a cloud-native payment processing platform built to demonstrate modern DevOps best practices including:

- ✅ Version-controlled source code (Git)
- ✅ Automated builds (GitHub Actions)
- ✅ Testing pipelines (Jest)
- ✅ Containerization (Docker)
- ✅ Infrastructure as Code (Terraform)
- ✅ CI/CD and GitOps workflows
- ✅ Self-hosted runners on EC2

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js 20 LTS |
| Framework | Express.js + TypeScript |
| Database | PostgreSQL 15 (RDS) |
| Cache | Redis 7 (ElastiCache) |
| Container | Docker (Alpine) |
| Orchestration | Kubernetes (EKS) |
| IaC | Terraform |
| CI/CD | GitHub Actions |
| Cloud | AWS |

---

## Architecture

```
                                    ┌─────────────────────────────────────┐
                                    │           AWS Cloud                  │
                                    │                                     │
┌──────────────┐                    │  ┌───────────────────────────────┐  │
│   Developer  │─────push───────────│──│         EKS Cluster            │  │
│   Workstation│                    │  │  ┌─────────┐  ┌─────────┐     │  │
└──────────────┘                    │  │  │ Payment │  │ Worker  │     │  │
       │                            │  │  │   API   │  │  Pods   │     │  │
       │                            │  │  │  Pods   │  │         │     │  │
       ▼                            │  │  └────┬────┘  └────┬────┘     │  │
┌──────────────┐                    │  │       │            │          │  │
│   GitHub     │                    │  │       ▼            ▼          │  │
│   Actions    │────deploy──────────│──│    ┌─────────────────────┐   │  │
│   Pipeline   │                    │  │    │   Application LB    │   │  │
└──────────────┘                    │  │    └─────────────────────┘   │  │
       │                            │  └───────────────────────────────┘  │
       │                            │                                     │
       │                            │  ┌──────────┐  ┌──────────┐        │
       │                            │  │   RDS    │  │ ElastiCache│       │
       │                            │  │ Postgres │  │   Redis   │        │
       │                            │  └──────────┘  └──────────┘        │
       │                            └─────────────────────────────────────┘
       │
       └─── EC2 Self-Hosted Runner executes all build/test/deploy steps
```

---

## Getting Started

### Prerequisites

- Node.js 20+
- Docker Desktop
- kubectl
- Terraform 1.5+
- AWS CLI configured

### Local Development

```bash
# Clone the repository
git clone https://github.com/nebulapay/nebulapay-ops.git
cd nebulapay-ops

# Start development environment
make dev

# Or run with Docker Compose
make dev-docker
```

### Verify Setup

```bash
# Run tests
make test

# Build the application
make build

# Build Docker image
make build-image
```

---

## CI/CD Pipeline

### Pipeline Stages

```
┌─────────────────────────────────────────────────────────────────┐
│                     CI/CD Pipeline Flow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Lint & Security Scan (EC2 Runner)                           │
│     ├── npm ci                                                   │
│     ├── npm run lint                                            │
│     ├── npm audit                                                │
│     └── npm run typecheck                                        │
│                                                                  │
│  2. Automated Testing (EC2 Runner) ⭐ BUILD CONFIRMATION        │
│     ├── npm run test --coverage                                 │
│     ├── Upload coverage to Codecov                              │
│     └── ✅ BUILD SUCCESSFUL confirmation                         │
│                                                                  │
│  3. Build & Push Container (EC2 Runner)                         │
│     ├── Docker buildx setup                                     │
│     ├── Build multi-arch image                                  │
│     └── Push to GHCR                                            │
│                                                                  │
│  4. Infrastructure Validation (EC2 Runner)                      │
│     ├── terraform fmt -check                                    │
│     ├── terraform validate                                      │
│     └── Checkov security scan                                   │
│                                                                  │
│  5. Deploy to Staging (GitOps)                                  │
│     ├── Update Kubernetes manifests                             │
│     ├── kubectl apply                                           │
│     └── Smoke tests                                             │
│                                                                  │
│  6. Production Deployment (Manual Approval)                     │
│     └── Same as staging with additional checks                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Build Confirmation

The **EC2 Self-Hosted Runner** confirms successful builds at multiple stages:

```yaml
# From .github/workflows/ci-cd.yml
- name: ✅ Confirm build success
  run: |
    echo "✅ BUILD SUCCESSFUL on EC2 Self-Hosted Runner"
    echo "Runner: $(hostname)"
    echo "Timestamp: $(date -u)"
```

---

## EC2 Self-Hosted Runner

### Setup Instructions

#### 1. Launch EC2 Instance

```bash
# AWS CLI
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.medium \
  --key-name your-key \
  --security-group-ids sg-xxxxx \
  --iam-instance-profile Name=GitHubRunnerProfile \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nebulapay-runner}]'
```

#### 2. Install Dependencies

```bash
# SSH into the instance
ssh -i your-key.pem ubuntu@<ec2-ip>

# Update and install
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io git curl unzip awscli

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu
newgrp docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

#### 3. Install GitHub Actions Runner

```bash
cd /home/ubuntu

# Download latest runner
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -O -L https://github.com/actions/runner/releases/download/${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION#v}.tar.gz

# Extract
tar xzf actions-runner-linux-x64-*.tar.gz

# Configure (get token from GitHub repo Settings > Actions > Runners > New self-hosted runner)
./config.sh --url https://github.com/nebulapay/nebulapay-ops --token YOUR_TOKEN --name ec2-runner-1 --labels aws,eks,production

# Install as service
sudo ./svc.sh install ubuntu
sudo ./svc.sh start

# Verify
sudo ./svc.sh status
```

#### 4. Verify Runner

Check in GitHub repository:
- Go to **Settings** → **Actions and workflows** → **Runners**
- You should see `ec2-runner-1` with status **Online**

---

## Infrastructure as Code

### Terraform Structure

```
infra/terraform/
├── main.tf              # Provider configuration
├── variables.tf         # Input variables
├── vpc.tf              # VPC, subnets, networking
├── eks.tf              # EKS cluster and node groups
├── database.tf         # RDS and ElastiCache
└── outputs.tf          # Output values
```

### Deploy Infrastructure

```bash
# Initialize Terraform
cd infra/terraform
terraform init

# Review changes
terraform plan

# Apply infrastructure
terraform apply

# Expected output:
# Apply complete! Resources: 45 added, 0 changed, 0 destroyed.
```

### Key Resources

| Resource | Description |
|----------|-------------|
| VPC | 3 AZs with public/private subnets |
| EKS Cluster | Kubernetes 1.28 with managed node groups |
| RDS PostgreSQL | Multi-AZ with automated backups |
| ElastiCache Redis | Cluster mode enabled for production |
| NAT Gateway | High availability across AZs |
| Security Groups | Least privilege access |

---

## Deployment Guide

### Staging Deployment

```bash
# Via Makefile
make deploy-staging

# Or manually
kubectl apply -f infra/kubernetes/staging/
kubectl rollout status deployment/nebulapay-payment-api -n staging
```

### Production Deployment

```bash
# Requires manual approval in GitHub Actions
# Trigger via workflow_dispatch

# Or manually
make deploy-production
```

### GitOps Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌─────────────┐
│   Developer │────▶│  Push to Git │────▶│   GitHub    │────▶│  EC2 Runner │
│             │     │   (main)     │     │   Actions   │     │   Executes  │
└─────────────┘     └──────────────┘     └─────────────┘     └─────────────┘
                                                                   │
                                                                   ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌─────────────┐
│   Monitor   │◀────│  Smoke Tests │◀────│  kubectl    │◀────│   Build &   │
│  Grafana    │     │   Pass        │     │   apply     │     │   Push      │
└─────────────┘     └──────────────┘     └─────────────┘     └─────────────┘
```

---

## Monitoring & Observability

### Prometheus Metrics

The application exposes metrics at `/metrics`:

```
# HELP nebulapay_http_request_duration_seconds Duration of HTTP requests
# TYPE nebulapay_http_request_duration_seconds histogram
nebulapay_http_request_duration_seconds_bucket{method="POST",route="/api/v1/payments",le="0.1"} 150

# HELP nebulapay_payments_total Total number of payments processed
# TYPE nebulapay_payments_total counter
nebulapay_payments_total{currency="USD",status="completed"} 1250
```

### Grafana Dashboards

Access Grafana at `http://localhost:3100` (default credentials: admin/admin)

Pre-configured dashboards:
- **Payment API Overview** - Request rates, latency, errors
- **Infrastructure** - CPU, memory, disk usage
- **Business Metrics** - Payment volume, success rates

### Alerts

```yaml
# Example alert rules
groups:
  - name: nebulapay-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        annotations:
          summary: "High error rate detected"
```

---

## Troubleshooting

### Common Issues

#### 1. Build Fails on EC2 Runner

```bash
# Check runner logs
sudo journalctl -u actions.runner.nebulapay-ops.ec2-runner-1 -f

# Verify Docker is running
sudo systemctl status docker
sudo docker info

# Check disk space
df -h
```

#### 2. Deployment Fails

```bash
# Check pod status
kubectl get pods -n staging
kubectl describe pod <pod-name> -n staging

# View logs
kubectl logs <pod-name> -n staging

# Check events
kubectl get events -n staging --sort-by='.lastTimestamp'
```

#### 3. Database Connection Issues

```bash
# Test connectivity from pod
kubectl exec -it <pod-name> -n staging -- nc -zv <db-host> 5432

# Check secrets
kubectl get secret nebulapay-db -n staging -o yaml
```

### Support

- **Documentation**: `/docs`
- **Runbook**: `/docs/runbook.md`
- **API Reference**: `/docs/api.md`

---

## Success Criteria

Your NebulaPay-OPS implementation is successful when:

- ✅ All CI/CD stages pass on EC2 self-hosted runner
- ✅ Build confirmation shows runner hostname
- ✅ Container image pushed to GHCR
- ✅ Terraform infrastructure deployed without errors
- ✅ Application deployed to EKS staging
- ✅ Health checks passing
- ✅ Metrics visible in Prometheus/Grafana
- ✅ Production deployment with manual approval works

---

**🎉 Congratulations! You've successfully built a modern cloud-native DevOps platform!**
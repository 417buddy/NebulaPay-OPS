# NebulaPay-OPS

Cloud-native payment processing platform demonstrating modern DevOps practices.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Cloud                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    EKS Cluster                        │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │   │
│  │  │ Payment API │  │   Worker    │  │   Monitor   │   │   │
│  │  │   Pods      │  │    Pods     │  │    Pods     │   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   RDS        │  │   ElastiCache│  │   S3         │       │
│  │  (PostgreSQL)│  │   (Redis)    │  │  (Assets)    │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                         ▲
                         │
┌────────────────────────┴────────────────────────┐
│              CI/CD Pipeline                      │
│  GitHub Actions → EC2 Self-Hosted Runner → EKS  │
└─────────────────────────────────────────────────┘
```

## Tech Stack

- **Runtime**: Node.js 20 LTS
- **Framework**: Express.js with TypeScript
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Container**: Docker (Alpine-based)
- **Orchestration**: Kubernetes (EKS)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions with EC2 Self-Hosted Runner

## Quick Start

```bash
# Local development
make dev

# Run tests
make test

# Build container
make build

# Deploy to staging
make deploy-staging
```

## Pipeline Status

[![CI/CD](https://github.com/nebulapay/nebulapay-ops/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/nebulapay/nebulapay-ops/actions)

## Documentation

- [Architecture](docs/architecture.md)
- [API Reference](docs/api.md)
- [Deployment Guide](docs/deployment.md)
- [Runbook](docs/runbook.md)

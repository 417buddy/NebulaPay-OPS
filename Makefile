# NebulaPay-OPS Makefile
# Modern DevOps Project Makefile

.PHONY: help dev build test lint clean deploy-staging deploy-production

# =============================================================================
# Variables
# =============================================================================
APP_NAME := nebulapay-payment-api
APP_DIR := apps/payment-api
DOCKERFILE := docker/Dockerfile
IMAGE_NAME := ghcr.io/nebulapay/$(APP_NAME)
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
KUBE_STAGING := infra/kubernetes/staging
KUBE_PRODUCTION := infra/kubernetes/production
CLUSTER_NAME := nebulapay-eks
AWS_REGION := us-east-1

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# =============================================================================
# Help
# =============================================================================
help: ## Display this help message
	@echo "$(BLUE)NebulaPay-OPS - Cloud-Native Payment Platform$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# Development
# =============================================================================
dev: ## Start local development environment
	@echo "$(BLUE)Starting NebulaPay development environment...$(NC)"
	cd $(APP_DIR) && npm install
	cd $(APP_DIR) && npm run dev

dev-docker: ## Start full stack with Docker Compose
	@echo "$(BLUE)Starting Docker Compose stack...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)Services started. Access:$(NC)"
	@echo "  - API: http://localhost:3000"
	@echo "  - Prometheus: http://localhost:9090"
	@echo "  - Grafana: http://localhost:3100 (admin/admin)"

dev-docker-logs: ## View Docker Compose logs
	docker-compose logs -f

dev-docker-stop: ## Stop Docker Compose stack
	docker-compose down

# =============================================================================
# Build
# =============================================================================
build: ## Build the application
	@echo "$(BLUE)Building $(APP_NAME)...$(NC)"
	cd $(APP_DIR) && npm install && npm run build
	@echo "$(GREEN)Build completed successfully!$(NC)"

build-image: ## Build Docker image
	@echo "$(BLUE)Building Docker image...$(NC)"
	docker build -f $(DOCKERFILE) -t $(IMAGE_NAME):$(VERSION) .
	@echo "$(GREEN)Image built: $(IMAGE_NAME):$(VERSION)$(NC)"

build-image-push: ## Build and push Docker image
	@echo "$(BLUE)Building and pushing Docker image...$(NC)"
	docker build -f $(DOCKERFILE) -t $(IMAGE_NAME):$(VERSION) .
	docker push $(IMAGE_NAME):$(VERSION)
	@echo "$(GREEN)Image pushed: $(IMAGE_NAME):$(VERSION)$(NC)"

# =============================================================================
# Testing
# =============================================================================
test: ## Run unit tests
	@echo "$(BLUE)Running tests...$(NC)"
	cd $(APP_DIR) && npm test
	@echo "$(GREEN)Tests completed!$(NC)"

test-coverage: ## Run tests with coverage report
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	cd $(APP_DIR) && npm run test -- --coverage
	@echo "$(GREEN)Coverage report generated in $(APP_DIR)/coverage$(NC)"

test-watch: ## Run tests in watch mode
	cd $(APP_DIR) && npm run test:watch

# =============================================================================
# Code Quality
# =============================================================================
lint: ## Run linter
	@echo "$(BLUE)Running linter...$(NC)"
	cd $(APP_DIR) && npm run lint
	@echo "$(GREEN)Lint completed!$(NC)"

lint-fix: ## Run linter with auto-fix
	@echo "$(BLUE)Running linter with auto-fix...$(NC)"
	cd $(APP_DIR) && npm run lint:fix

typecheck: ## Run TypeScript type check
	@echo "$(BLUE)Running type check...$(NC)"
	cd $(APP_DIR) && npm run typecheck
	@echo "$(GREEN)Type check completed!$(NC)"

# =============================================================================
# Clean
# =============================================================================
clean: ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	rm -rf $(APP_DIR)/dist
	rm -rf $(APP_DIR)/node_modules
	rm -rf $(APP_DIR)/coverage
	rm -rf $(APP_DIR)/.nyc_output
	@echo "$(GREEN)Clean completed!$(NC)"

# =============================================================================
# Kubernetes Deployment
# =============================================================================
deploy-staging: ## Deploy to staging environment
	@echo "$(BLUE)Deploying to staging...$(NC)"
	@kubectl cluster-info > /dev/null 2>&1 || (echo "$(RED)Error: Not connected to Kubernetes cluster$(NC)" && echo "Run 'aws eks update-kubeconfig --name $(CLUSTER_NAME)' first" && exit 1)
	@echo "$(YELLOW)Creating namespace...$(NC)"
	kubectl apply -f infra/kubernetes/base/
	@echo "$(YELLOW)Applying staging manifests...$(NC)"
	kubectl apply -f $(KUBE_STAGING)/
	kubectl rollout status deployment/$(APP_NAME) -n staging --timeout=300s
	@echo "$(GREEN)Staging deployment completed!$(NC)"

deploy-production: ## Deploy to production environment
	@echo "$(YELLOW)Deploying to production...$(NC)"
	@kubectl cluster-info > /dev/null 2>&1 || (echo "$(RED)Error: Not connected to Kubernetes cluster$(NC)" && echo "Run 'aws eks update-kubeconfig --name $(CLUSTER_NAME)' first" && exit 1)
	@echo "$(YELLOW)Creating namespace...$(NC)"
	kubectl apply -f infra/kubernetes/base/
	@echo "$(YELLOW)Applying production manifests...$(NC)"
	kubectl apply -f $(KUBE_PRODUCTION)/
	kubectl rollout status deployment/$(APP_NAME) -n production --timeout=600s
	@echo "$(GREEN)Production deployment completed!$(NC)"

deploy-rollback: ## Rollback last deployment
	@echo "$(YELLOW)Rolling back deployment...$(NC)"
	kubectl rollout undo deployment/$(APP_NAME)
	@echo "$(GREEN)Rollback completed!$(NC)"

# =============================================================================
# Infrastructure
# =============================================================================
infra-init: ## Initialize Terraform infrastructure
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	cd infra/terraform && terraform init
	@echo "$(GREEN)Terraform initialized!$(NC)"

infra-plan: ## Run Terraform plan
	@echo "$(BLUE)Running Terraform plan...$(NC)"
	cd infra/terraform && terraform plan -out=tfplan
	@echo "$(GREEN)Terraform plan completed!$(NC)"

infra-apply: ## Apply Terraform changes
	@echo "$(YELLOW)Applying Terraform changes...$(NC)"
	cd infra/terraform && terraform apply tfplan
	@echo "$(GREEN)Terraform apply completed!$(NC)"

infra-destroy: ## Destroy Terraform infrastructure
	@echo "$(RED)WARNING: This will destroy infrastructure!$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$confirm" = "y" ]
	cd infra/terraform && terraform destroy
	@echo "$(GREEN)Infrastructure destroyed!$(NC)"

kube-config: ## Configure kubectl to connect to EKS cluster
	@echo "$(BLUE)Configuring kubectl for EKS cluster...$(NC)"
	aws eks update-kubeconfig --name $(CLUSTER_NAME) --region $(AWS_REGION)
	@echo "$(GREEN)kubectl configured successfully!$(NC)"
	@kubectl cluster-info

kube-context: ## Show current kubectl context
	@echo "$(BLUE)Current kubectl context:$(NC)"
	@kubectl config current-context
	@echo ""
	@echo "$(BLUE)Cluster info:$(NC)"
	@kubectl cluster-info

# =============================================================================
# EC2 Runner Setup (Documentation)
# =============================================================================
setup-ec2-runner: ## Instructions for setting up EC2 self-hosted runner
	@echo "$(BLUE)EC2 Self-Hosted Runner Setup Instructions:$(NC)"
	@echo ""
	@echo "1. Launch EC2 instance (Ubuntu 22.04, t3.medium minimum)"
	@echo "2. Install dependencies:"
	@echo "   sudo apt update && sudo apt upgrade -y"
	@echo "   sudo apt install -y docker.io git curl unzip"
	@echo "   sudo usermod -aG docker ubuntu"
	@echo ""
	@echo "3. Install GitHub Actions Runner:"
	@echo "   cd /home/ubuntu"
	@echo "   curl -O -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz"
	@echo "   tar xzf actions-runner-linux-x64-2.311.0.tar.gz"
	@echo ""
	@echo "4. Configure runner (get token from GitHub repo Settings > Actions > Runners):"
	@echo "   ./config.sh --url https://github.com/YOUR_REPO --token YOUR_TOKEN --name ec2-runner-1"
	@echo ""
	@echo "5. Run as service:"
	@echo "   sudo ./svc.sh install ubuntu"
	@echo "   sudo ./svc.sh start"
	@echo ""
	@echo "$(GREEN)Runner setup complete!$(NC)"

# =============================================================================
# Monitoring
# =============================================================================
logs: ## View application logs
	kubectl logs -f deployment/$(APP_NAME) -n staging

logs-prod: ## View production logs
	kubectl logs -f deployment/$(APP_NAME) -n production

port-forward: ## Port forward to staging API
	kubectl port-forward svc/payment-api 3000:80 -n staging

# =============================================================================
# Database
# =============================================================================
db-migrate: ## Run database migrations
	@echo "$(BLUE)Running database migrations...$(NC)"
	cd $(APP_DIR) && npm run migrate

db-seed: ## Seed database with sample data
	@echo "$(BLUE)Seeding database...$(NC)"
	cd $(APP_DIR) && npm run seed
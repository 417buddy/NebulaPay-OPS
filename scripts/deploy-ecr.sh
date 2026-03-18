#!/bin/bash
set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  NebulaPay-OPS ECR Build & Deploy     ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Configuration
ECR_REPO="564268554451.dkr.ecr.us-east-1.amazonaws.com/nebulapay/payment-api"
VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "latest")
NAMESPACE="${1:-staging}"

echo -e "${YELLOW}Configuration:${NC}"
echo "  ECR Repository: $ECR_REPO"
echo "  Version: $VERSION"
echo "  Target Namespace: $NAMESPACE"
echo ""

# Step 1: Login to ECR
echo -e "${YELLOW}Step 1: Logging into ECR...${NC}"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 564268554451.dkr.ecr.us-east-1.amazonaws.com
echo -e "${GREEN}✓ Logged into ECR${NC}"
echo ""

# Step 2: Build Docker image
echo -e "${YELLOW}Step 2: Building Docker image...${NC}"
cd /Users/owolabiyusuff/nebulapay-ops
docker build -f docker/Dockerfile -t ${ECR_REPO}:${VERSION} .
docker tag ${ECR_REPO}:${VERSION} ${ECR_REPO}:latest
echo -e "${GREEN}✓ Image built: ${ECR_REPO}:${VERSION}${NC}"
echo ""

# Step 3: Push to ECR
echo -e "${YELLOW}Step 3: Pushing image to ECR...${NC}"
docker push ${ECR_REPO}:${VERSION}
docker push ${ECR_REPO}:latest
echo -e "${GREEN}✓ Image pushed to ECR${NC}"
echo ""

# Step 4: Update Kubernetes deployment
echo -e "${YELLOW}Step 4: Updating Kubernetes deployment...${NC}"
cd /Users/owolabiyusuff/nebulapay-ops/infra/kubernetes/$NAMESPACE
sed -i.bak "s|image: .*payment-api.*|image: ${ECR_REPO}:${VERSION}|g" deployment.yaml
rm -f deployment.yaml.bak
echo -e "${GREEN}✓ Deployment updated${NC}"
echo ""

# Step 5: Create namespace
echo -e "${YELLOW}Step 5: Creating namespace...${NC}"
kubectl apply -f ../base/
echo -e "${GREEN}✓ Namespace created: $NAMESPACE${NC}"
echo ""

# Step 6: Apply Kubernetes manifests
echo -e "${YELLOW}Step 6: Applying Kubernetes manifests...${NC}"
kubectl apply -f .
echo -e "${GREEN}✓ Manifests applied${NC}"
echo ""

# Step 7: Wait for rollout
echo -e "${YELLOW}Step 7: Waiting for deployment rollout...${NC}"
kubectl rollout status deployment/nebulapay-payment-api -n $NAMESPACE --timeout=300s
echo -e "${GREEN}✓ Deployment rolled out successfully${NC}"
echo ""

# Step 8: Show status
echo -e "${YELLOW}Step 8: Deployment status${NC}"
echo ""
kubectl get pods -n $NAMESPACE
echo ""
kubectl get svc -n $NAMESPACE
echo ""

# Step 9: Show logs (optional)
echo -e "${YELLOW}View logs with:${NC}"
echo "  kubectl logs -f deployment/nebulapay-payment-api -n $NAMESPACE"
echo ""
echo -e "${YELLOW}Port-forward to test:${NC}"
echo "  kubectl port-forward svc/payment-api 3000:80 -n $NAMESPACE"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ Deployment Complete!               ${NC}"
echo -e "${GREEN}========================================${NC}"

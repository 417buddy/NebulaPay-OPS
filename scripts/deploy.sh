# Quick Deploy Script for NebulaPay-OPS
# This script builds the Docker image and deploys to Kubernetes

#!/bin/bash
set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  NebulaPay-OPS Quick Deploy Script    ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Configuration
NAMESPACE="${1:-staging}"
IMAGE_NAME="ghcr.io/nebulapay/nebulapay-payment-api"
VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "dev")

echo -e "${YELLOW}Configuration:${NC}"
echo "  Namespace: $NAMESPACE"
echo "  Image: $IMAGE_NAME:$VERSION"
echo "  Context: $(kubectl config current-context)"
echo ""

# Step 1: Check cluster connection
echo -e "${YELLOW}Step 1: Checking cluster connection...${NC}"
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo -e "${RED}Error: Not connected to Kubernetes cluster${NC}"
    echo "Run: aws eks update-kubeconfig --name nebulapay-eks --region us-east-1"
    exit 1
fi
echo -e "${GREEN}✓ Cluster connected${NC}"
echo ""

# Step 2: Build Docker image
echo -e "${YELLOW}Step 2: Building Docker image...${NC}"
cd apps/payment-api
docker build -f ../../docker/Dockerfile -t ${IMAGE_NAME}:${VERSION} .
docker tag ${IMAGE_NAME}:${VERSION} ${IMAGE_NAME}:latest
echo -e "${GREEN}✓ Image built: ${IMAGE_NAME}:${VERSION}${NC}"
echo ""

# Step 3: Push to registry (optional - skip for local clusters)
echo -e "${YELLOW}Step 3: Pushing image to registry...${NC}"
if docker push ${IMAGE_NAME}:${VERSION} && docker push ${IMAGE_NAME}:latest; then
    echo -e "${GREEN}✓ Image pushed${NC}"
else
    echo -e "${YELLOW}⚠ Push failed (this is OK for local clusters like kind/minikube)${NC}"
    echo "  Continuing with local image..."
fi
echo ""

# Step 4: Create namespace
echo -e "${YELLOW}Step 4: Creating namespace...${NC}"
kubectl apply -f ../../infra/kubernetes/base/
echo -e "${GREEN}✓ Namespace created: $NAMESPACE${NC}"
echo ""

# Step 5: Update deployment image
echo -e "${YELLOW}Step 5: Updating deployment image...${NC}"
cd ../../infra/kubernetes/$NAMESPACE
sed -i.bak "s|image: .*payment-api.*|image: ${IMAGE_NAME}:${VERSION}|g" deployment.yaml
echo -e "${GREEN}✓ Deployment updated with image: ${IMAGE_NAME}:${VERSION}${NC}"
echo ""

# Step 6: Apply Kubernetes manifests
echo -e "${YELLOW}Step 6: Applying Kubernetes manifests...${NC}"
kubectl apply -f .
echo -e "${GREEN}✓ Manifests applied${NC}"
echo ""

# Step 7: Wait for rollout
echo -e "${YELLOW}Step 7: Waiting for deployment rollout...${NC}"
kubectl rollout status deployment/nebulapay-payment-api -n $NAMESPACE --timeout=300s
echo -e "${GREEN}✓ Deployment rolled out${NC}"
echo ""

# Step 8: Show status
echo -e "${YELLOW}Step 8: Deployment status${NC}"
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Complete!                 ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "To view logs: ${BLUE}kubectl logs -f deployment/nebulapay-payment-api -n $NAMESPACE${NC}"
echo -e "To port-forward: ${BLUE}kubectl port-forward svc/payment-api 3000:80 -n $NAMESPACE${NC}"
echo ""

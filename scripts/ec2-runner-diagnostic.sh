#!/bin/bash

# NebulaPay-OPS EC2 Runner Troubleshooting Script
# Run this on your EC2 instance to diagnose issues

echo "=========================================="
echo "  NEBULAPAY-OPS RUNNER DIAGNOSTIC TOOL  "
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service
check_service() {
    if systemctl is-active --quiet "$1"; then
        echo -e "${GREEN}✅ $1 is running${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 is not running${NC}"
        return 1
    fi
}

# Function to check command
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✅ $1 installed: $($1 --version 2>&1 | head -1)${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 not installed${NC}"
        return 1
    fi
}

echo "1. SYSTEM INFORMATION"
echo "----------------------------------------"
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2)"
echo "Kernel: $(uname -r)"
echo "CPU: $(nproc) cores"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
echo ""

echo "2. REQUIRED SOFTWARE"
echo "----------------------------------------"
check_command node
check_command npm
check_command docker
check_command git
check_command terraform
check_command kubectl
aws --version 2>&1 | head -1
echo ""

echo "3. DOCKER STATUS"
echo "----------------------------------------"
check_service docker
docker ps -a --no-trunc | head -5
echo ""

echo "4. GITHUB RUNNER SERVICE"
echo "----------------------------------------"
RUNNER_SERVICE=$(systemctl list-units --type=service --all | grep "actions.runner" | awk '{print $1}')
if [ -n "$RUNNER_SERVICE" ]; then
    check_service "$RUNNER_SERVICE"
    echo ""
    echo "Service Status:"
    systemctl status "$RUNNER_SERVICE" --no-pager | head -15
    echo ""
    echo "Recent Logs (last 10 entries):"
    sudo journalctl -u "$RUNNER_SERVICE" -n 10 --no-pager
else
    echo -e "${RED}❌ GitHub Actions Runner service not found${NC}"
    echo ""
    echo "Runner directory contents:"
    ls -la /home/ubuntu/actions-runner/ 2>/dev/null || echo "Runner directory not found"
fi
echo ""

echo "5. RUNNER CONFIGURATION"
echo "----------------------------------------"
if [ -f /home/ubuntu/actions-runner/.runner ]; then
    echo "Runner Configuration:"
    cat /home/ubuntu/actions-runner/.runner | jq .
else
    echo -e "${RED}❌ Runner configuration file not found${NC}"
fi
echo ""

echo "6. NETWORK CONNECTIVITY"
echo "----------------------------------------"
echo "Testing GitHub connectivity..."
curl -s -o /dev/null -w "GitHub API: %{http_code}\n" https://api.github.com
curl -s -o /dev/null -w "GitHub.com: %{http_code}\n" https://github.com
echo ""
echo "Testing AWS connectivity..."
aws sts get-caller-identity 2>&1 | grep Arn || echo "AWS credentials not configured"
echo ""

echo "7. FILE PERMISSIONS"
echo "----------------------------------------"
echo "Runner directory permissions:"
ls -la /home/ubuntu/actions-runner/ | head -10
echo ""
echo "Ubuntu user groups:"
groups ubuntu
echo ""

echo "8. RUNNING PROCESSES"
echo "----------------------------------------"
ps aux | grep -E "(node|docker|runner)" | grep -v grep | head -10
echo ""

echo "9. AVAILABLE DISK SPACE"
echo "----------------------------------------"
df -h
echo ""

echo "10. RECOMMENDATIONS"
echo "--------------------------------=========="

ISSUES=0

if ! systemctl is-active --quiet docker; then
    echo -e "${YELLOW}⚠️  Docker is not running. Start with: sudo systemctl start docker${NC}"
    ISSUES=$((ISSUES+1))
fi

if [ -n "$RUNNER_SERVICE" ] && ! systemctl is-active --quiet "$RUNNER_SERVICE"; then
    echo -e "${YELLOW}⚠️  Runner service is not running. Start with: sudo ./svc.sh start${NC}"
    ISSUES=$((ISSUES+1))
fi

if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not installed${NC}"
    ISSUES=$((ISSUES+1))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ All systems appear to be working correctly!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Go to https://github.com/417buddy/NebulaPay-OPS/actions"
    echo "2. Click on 'Test EC2 Runner' workflow"
    echo "3. Click 'Run workflow' to manually trigger"
    echo "4. Watch the logs in real-time"
    echo ""
    echo "To monitor runner logs in real-time:"
    echo "  sudo journalctl -u $RUNNER_SERVICE -f"
else
    echo -e "${RED}⚠️  Found $ISSUES issue(s) that need attention${NC}"
fi

echo ""
echo "=========================================="
echo "  DIAGNOSTIC COMPLETE                    "
echo "=========================================="
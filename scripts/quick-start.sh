#!/bin/bash
# OpenClaw Multi-Deployment - Quick Start (One-Click Deploy)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
REGION="us-west-2"
KEY_PAIR=""
EMAIL=""
INSTANCE_NAME="openclaw-1"
INSTANCE_TYPE="t4g.medium"
BEDROCK_MODEL="global.amazon.nova-2-lite-v1:0"
SKIP_FOUNDATION=false

# Banner
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║        OpenClaw Multi-Deployment - Quick Start            ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║        Deploy complete OpenClaw infrastructure            ║${NC}"
echo -e "${CYAN}║        in 15 minutes with one command                     ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --region)
      REGION="$2"
      shift 2
      ;;
    --key-pair)
      KEY_PAIR="$2"
      shift 2
      ;;
    --email)
      EMAIL="$2"
      shift 2
      ;;
    --instance-name)
      INSTANCE_NAME="$2"
      shift 2
      ;;
    --instance-type)
      INSTANCE_TYPE="$2"
      shift 2
      ;;
    --model)
      BEDROCK_MODEL="$2"
      shift 2
      ;;
    --skip-foundation)
      SKIP_FOUNDATION=true
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Quick start deployment for OpenClaw Multi-Deployment"
      echo ""
      echo "Options:"
      echo "  --region REGION          AWS region (default: us-west-2)"
      echo "  --key-pair NAME          EC2 key pair name (required)"
      echo "  --email EMAIL            Email for notifications (optional)"
      echo "  --instance-name NAME     First instance name (default: openclaw-1)"
      echo "  --instance-type TYPE     EC2 instance type (default: t4g.medium)"
      echo "  --model MODEL_ID         Bedrock model (default: nova-2-lite)"
      echo "  --skip-foundation        Skip foundation deployment (if already exists)"
      echo "  --help                   Show this help message"
      echo ""
      echo "Example:"
      echo "  $0 --key-pair my-key --email me@example.com"
      echo ""
      echo "What this does:"
      echo "  1. Validates prerequisites"
      echo "  2. Deploys VPC foundation (~10 min)"
      echo "  3. Deploys shared resources (~5 min)"
      echo "  4. Deploys first OpenClaw instance (~5 min)"
      echo "  5. Prints access URL and credentials"
      echo ""
      echo "Total time: ~15 minutes"
      echo "Total cost: ~$125/month (foundation + 1 instance)"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Validate inputs
if [ -z "$KEY_PAIR" ]; then
  echo -e "${RED}Error: --key-pair is required${NC}"
  echo "Example: $0 --key-pair my-keypair"
  echo ""
  echo "List your key pairs:"
  echo "  aws ec2 describe-key-pairs --region $REGION --query 'KeyPairs[*].KeyName'"
  exit 1
fi

# Step 1: Prerequisites check
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
  echo -e "${RED}✗ AWS CLI not found${NC}"
  echo "Install: https://aws.amazon.com/cli/"
  exit 1
fi
echo -e "${GREEN}✓ AWS CLI installed${NC}"

# Check credentials
if ! aws sts get-caller-identity &> /dev/null; then
  echo -e "${RED}✗ AWS credentials not configured${NC}"
  echo "Run: aws configure"
  exit 1
fi
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo -e "${GREEN}✓ AWS credentials valid (Account: $ACCOUNT_ID)${NC}"

# Check Bedrock access
echo -n "Checking Bedrock access... "
if aws bedrock list-foundation-models --region $REGION &> /dev/null; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${YELLOW}⚠ Cannot verify Bedrock access${NC}"
  echo "  Make sure Bedrock is enabled in your region"
fi

# Verify key pair
echo -n "Verifying Key Pair '$KEY_PAIR'... "
if aws ec2 describe-key-pairs --region $REGION --key-names $KEY_PAIR &> /dev/null; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗ Key pair not found${NC}"
  echo ""
  echo "Available key pairs:"
  aws ec2 describe-key-pairs --region $REGION --query 'KeyPairs[*].KeyName' --output table
  exit 1
fi

echo ""
echo -e "${GREEN}All prerequisites satisfied!${NC}"
echo ""

# Step 2: Display deployment plan
echo -e "${YELLOW}[2/6] Deployment Plan${NC}"
echo ""
echo "Region:             $REGION"
echo "Key Pair:           $KEY_PAIR"
echo "Instance Name:      $INSTANCE_NAME"
echo "Instance Type:      $INSTANCE_TYPE"
echo "Bedrock Model:      $BEDROCK_MODEL"
if [ -n "$EMAIL" ]; then
  echo "Notification Email: $EMAIL"
fi
echo ""
echo -e "${CYAN}Infrastructure:${NC}"
if [ "$SKIP_FOUNDATION" = false ]; then
  echo "  • VPC Foundation       (~10 min)"
  echo "  • Shared Resources     (~5 min)"
fi
echo "  • OpenClaw Instance    (~5 min)"
echo ""
echo -e "${CYAN}Monthly Cost Estimate:${NC}"
if [ "$SKIP_FOUNDATION" = false ]; then
  echo "  • Foundation (shared): $70"
  echo "  • Instance:            $33"
  echo "  • Total:               $103/month"
else
  echo "  • Instance only:       $33/month"
fi
echo ""
read -p "Continue with deployment? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Deployment cancelled."
  exit 0
fi

# Step 3: Deploy Foundation
if [ "$SKIP_FOUNDATION" = false ]; then
  echo ""
  echo -e "${YELLOW}[3/6] Deploying VPC Foundation...${NC}"
  echo "This will take approximately 10 minutes."
  echo ""
  
  ./scripts/deploy-foundation.sh \
    --region $REGION \
    --key-pair $KEY_PAIR \
    --stack-name openclaw-foundation \
    --shared-stack-name openclaw-shared \
    $([ -n "$EMAIL" ] && echo "--email $EMAIL")
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}Foundation deployment failed!${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✓ Foundation deployed successfully${NC}"
else
  echo ""
  echo -e "${YELLOW}[3/6] Skipping foundation deployment${NC}"
  echo "Using existing foundation stacks"
fi

# Step 4: Deploy First Instance
echo ""
echo -e "${YELLOW}[4/6] Deploying OpenClaw Instance: $INSTANCE_NAME${NC}"
echo "This will take approximately 5 minutes."
echo ""

./scripts/deploy-instance.sh \
  --region $REGION \
  --name $INSTANCE_NAME \
  --key-pair $KEY_PAIR \
  --instance-type $INSTANCE_TYPE \
  --model $BEDROCK_MODEL

if [ $? -ne 0 ]; then
  echo -e "${RED}Instance deployment failed!${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Instance deployed successfully${NC}"

# Step 5: Wait for instance to be ready
echo ""
echo -e "${YELLOW}[5/6] Waiting for OpenClaw to start...${NC}"
echo "This may take 2-3 minutes for initial setup."
echo ""

sleep 120  # Wait 2 minutes for user data to run

echo -e "${GREEN}✓ Instance should be ready${NC}"

# Step 6: Display access information
echo ""
echo -e "${YELLOW}[6/6] Deployment Complete! 🎉${NC}"
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║                 🎉 DEPLOYMENT SUCCESSFUL 🎉                ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get access URL
ALB_URL=$(aws cloudformation describe-stacks \
  --region $REGION \
  --stack-name openclaw-shared \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
  --output text 2>/dev/null)

# Get gateway token
TOKEN=$(aws ssm get-parameter \
  --region $REGION \
  --name /openclaw/$INSTANCE_NAME/token \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text 2>/dev/null)

echo -e "${GREEN}Access Information:${NC}"
echo ""
echo "Base URL:    ${ALB_URL}/${INSTANCE_NAME}/"
echo "Full URL:    ${ALB_URL}/${INSTANCE_NAME}/?token=${TOKEN}"
echo ""
echo -e "${BLUE}Copy this URL and open it in your browser:${NC}"
echo -e "${CYAN}${ALB_URL}/${INSTANCE_NAME}/?token=${TOKEN}${NC}"
echo ""
echo -e "${GREEN}Management Commands:${NC}"
echo ""
echo "Check health:"
echo "  ./scripts/health-check.sh --instance $INSTANCE_NAME"
echo ""
echo "List all instances:"
echo "  ./scripts/list-instances.sh"
echo ""
echo "Deploy more instances:"
echo "  ./scripts/deploy-instance.sh --name openclaw-2 --key-pair $KEY_PAIR"
echo ""
echo "Scale instance:"
echo "  ./scripts/scale-instances.sh --instance $INSTANCE_NAME --desired 3"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo ""
echo "1. Open the URL above in your browser"
echo "2. Connect messaging channels (WhatsApp/Telegram/Discord)"
echo "3. Start chatting with your AI assistant!"
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "  • Quick Start:  QUICKSTART.md"
echo "  • Management:   docs/MANAGEMENT.md"
echo "  • Architecture: ARCHITECTURE.md"
echo ""
echo -e "${YELLOW}Cost Reminder:${NC}"
if [ "$SKIP_FOUNDATION" = false ]; then
  echo "  Your deployment will cost approximately \$103/month"
else
  echo "  Your instance will cost approximately \$33/month"
fi
echo "  Remember to delete resources when not needed!"
echo ""
echo "To delete everything:"
echo "  ./scripts/cleanup-all.sh --confirm"
echo ""
echo -e "${GREEN}Enjoy your OpenClaw deployment! 🚀${NC}"
echo ""

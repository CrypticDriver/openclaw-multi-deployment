# 🚀 One-Click Deployment Guide

## Quick Launch (One-Click)

### Option 1: Launch via CloudFormation Console

Click the button below to deploy the complete infrastructure in one click:

**Step 1: Deploy Foundation (VPC + Shared Resources)**

[![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=openclaw-foundation&templateURL=https://openclaw-deployment.s3.us-west-2.amazonaws.com/cloudformation/foundation-all-in-one.yaml)

**Step 2: Deploy Your First Instance**

[![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=openclaw-instance-1&templateURL=https://openclaw-deployment.s3.us-west-2.amazonaws.com/cloudformation/openclaw-instance.yaml)

**Total time:** ~15 minutes  
**Total cost:** ~$100/month (foundation + 1 instance)

---

## Option 2: One-Command Deployment (CLI)

### Prerequisites

- AWS CLI installed and configured
- Admin permissions (or CloudFormation + EC2 + VPC + IAM)
- An EC2 Key Pair for SSH access

### Deploy Everything

```bash
# One command to deploy foundation + first instance
curl -fsSL https://openclaw-deployment.s3.us-west-2.amazonaws.com/quick-start.sh | bash -s -- \
  --key-pair your-keypair-name \
  --email your-email@example.com
```

**What this does:**
1. Validates prerequisites
2. Deploys VPC foundation (~10 min)
3. Deploys shared resources (~5 min)
4. Deploys first OpenClaw instance (~5 min)
5. Sends you the access URL via email

**Manual step-by-step (if you prefer):**

```bash
# 1. Clone repo
git clone https://github.com/CrypticDriver/openclaw-multi-deployment.git
cd openclaw-multi-deployment

# 2. Run one-click script
./scripts/quick-start.sh \
  --region us-west-2 \
  --key-pair your-keypair-name \
  --email your-email@example.com \
  --instance-name my-openclaw
```

---

## Option 3: Nested Stack (True One-Click)

**Coming soon:** Single CloudFormation template that deploys everything.

Deploy the entire infrastructure with one click:

```bash
aws cloudformation create-stack \
  --stack-name openclaw-complete \
  --template-url https://openclaw-deployment.s3.us-west-2.amazonaws.com/cloudformation/master.yaml \
  --parameters \
    ParameterKey=KeyPairName,ParameterValue=your-keypair \
    ParameterKey=InstanceCount,ParameterValue=1 \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## What You Get

After deployment completes:

✅ **VPC Foundation**
- Multi-AZ private/public subnets
- NAT Gateway for internet access
- VPC Flow Logs for security

✅ **Shared Resources**
- Application Load Balancer (ALB)
- VPC Endpoints (S3, Bedrock, SSM)
- CloudWatch Log Groups
- SNS Topic for alerts

✅ **OpenClaw Instance**
- Auto Scaling Group (1-3 instances)
- Pre-installed OpenClaw
- Automatic Bedrock integration
- Web UI access URL

✅ **Access Information**
```
Access URL: http://openclaw-alb-xxxx.us-west-2.elb.amazonaws.com/my-openclaw/
Gateway Token: (stored in SSM Parameter Store)
```

---

## Cost Breakdown

| Component | Monthly Cost |
|-----------|-------------|
| VPC Foundation (shared) | $48 |
| ALB (shared) | $22 |
| VPC Endpoints (shared) | $22 |
| **Foundation Total** | **$92** |
| | |
| Each OpenClaw Instance | $31 |
| EBS Storage (30GB) | $2.40 |
| **Per-Instance Total** | **$33.40** |
| | |
| **1 Instance Total** | **$125.40/month** |
| **5 Instances Total** | **$259/month** |
| **10 Instances Total** | **$426/month** |

---

## Cleanup (Delete Everything)

One command to delete all resources:

```bash
./scripts/cleanup-all.sh --confirm
```

Or manual cleanup:

```bash
# Delete all instances
aws cloudformation delete-stack --stack-name openclaw-instance-1

# Delete shared resources
aws cloudformation delete-stack --stack-name openclaw-shared

# Delete foundation
aws cloudformation delete-stack --stack-name openclaw-foundation
```

---

## Troubleshooting

### Stack creation failed?

Check CloudFormation events:
```bash
aws cloudformation describe-stack-events \
  --stack-name openclaw-foundation \
  --max-items 10
```

### Can't find Key Pair?

List available keys:
```bash
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName'
```

Create new key:
```bash
aws ec2 create-key-pair \
  --key-name openclaw-key \
  --query 'KeyMaterial' \
  --output text > openclaw-key.pem
chmod 400 openclaw-key.pem
```

### Need help?

- Check logs: CloudWatch Logs → `/openclaw/[instance-name]`
- Health check: `./scripts/health-check.sh --all`
- Support: Open an issue on GitHub

---

## Next Steps

After successful deployment:

1. **Access Web UI**
   ```bash
   ./scripts/list-instances.sh --show-tokens
   ```

2. **Connect Messaging**
   - WhatsApp: Scan QR code in UI
   - Telegram: Create bot via BotFather
   - Discord: Add bot via OAuth

3. **Deploy More Instances**
   ```bash
   ./scripts/deploy-instance.sh --name openclaw-2 --key-pair your-key
   ```

4. **Scale Up**
   ```bash
   ./scripts/scale-instances.sh --instance openclaw-1 --desired 3
   ```

---

**Total Setup Time:** 15 minutes  
**Difficulty:** Easy (just click buttons)  
**Prerequisites:** AWS account + Key Pair

**Ready to deploy?** [Click here to launch →](#option-1-launch-via-cloudformation-console)

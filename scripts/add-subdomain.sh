#!/bin/bash
# Add subdomain routing to existing ALB

set -e

REGION="us-west-2"
INSTANCE_NAME=$1
SUBDOMAIN=$2
HOSTED_ZONE_ID=$3

if [ -z "$INSTANCE_NAME" ] || [ -z "$SUBDOMAIN" ] || [ -z "$HOSTED_ZONE_ID" ]; then
  echo "Usage: $0 <instance-name> <subdomain> <hosted-zone-id>"
  echo ""
  echo "Example:"
  echo "  $0 openclaw-1 user-a Z1234567890ABC"
  echo ""
  echo "This creates:"
  echo "  user-a.openclaw.yourdomain.com → openclaw-1"
  exit 1
fi

# Get ALB ARN
LISTENER_ARN=$(aws cloudformation describe-stacks \
  --region $REGION \
  --stack-name openclaw-shared \
  --query 'Stacks[0].Outputs[?OutputKey==`HTTPListenerArn`].OutputValue' \
  --output text)

# Get Target Group ARN
TG_ARN=$(aws cloudformation describe-stacks \
  --region $REGION \
  --stack-name openclaw-$INSTANCE_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupArn`].OutputValue' \
  --output text)

# Add listener rule for subdomain
PRIORITY=$((10000 + RANDOM % 10000))

aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN \
  --priority $PRIORITY \
  --conditions Field=host-header,Values=$SUBDOMAIN.openclaw.yourdomain.com \
  --actions Type=forward,TargetGroupArn=$TG_ARN

echo "✓ Created ALB rule: $SUBDOMAIN.openclaw.yourdomain.com → $INSTANCE_NAME"

# Create Route53 record
cat > /tmp/route53-change.json << EOF
{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "$SUBDOMAIN.openclaw.yourdomain.com",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[0].CanonicalHostedZoneId' --output text)",
        "DNSName": "$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[0].DNSName' --output text)",
        "EvaluateTargetHealth": false
      }
    }
  }]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file:///tmp/route53-change.json

echo "✓ Created DNS record: $SUBDOMAIN.openclaw.yourdomain.com"
echo ""
echo "Access URL: https://$SUBDOMAIN.openclaw.yourdomain.com/?token=YOUR_TOKEN"

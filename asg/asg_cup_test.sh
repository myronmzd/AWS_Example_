#!/bin/bash

# Variables
ASG_NAME="MyAutoScalingGroup"
REGION="ap-south-1"
KEY_PATH="MyKeyPair.pem"  # Update this with your key path
STRESS_DURATION=300

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Error handling
set -e
trap 'echo "Error on line $LINENO"' ERR

# Check if key file exists
if [ ! -f "${KEY_PATH/#\~/$HOME}" ]; then
    echo -e "${RED}❌ SSH key not found at $KEY_PATH${NC}"
    echo "Please update KEY_PATH in the script with your correct key location"
    exit 1
fi

# Ensure correct key permissions
chmod 400 "${KEY_PATH/#\~/$HOME}"

# Step 1: Get the Public IP of the running ASG instance
echo -e "${YELLOW}🔎 Fetching instance details...${NC}"
INSTANCE_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:aws:autoscaling:groupName,Values=$ASG_NAME" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region $REGION)

if [[ -z "$INSTANCE_IP" ]]; then
    echo -e "${RED}❌ No running instance found in ASG $ASG_NAME!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found running instance at $INSTANCE_IP${NC}"

# Step 2: Connect via SSH and generate CPU stress
echo -e "${YELLOW}⚙️ Connecting to instance and running CPU stress test...${NC}"
ssh -i "${KEY_PATH/#\~/$HOME}" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    ec2-user@"$INSTANCE_IP" << 'EOF'
    # Install stress if not present
    if ! command -v stress &>/dev/null; then
        echo "📦 Installing stress utility..."
        if grep -q "Amazon Linux release 2023" /etc/os-release; then
            sudo dnf install -y stress
        elif grep -q "Amazon Linux release 2" /etc/os-release; then
            sudo amazon-linux-extras install epel -y
            sudo yum install -y stress
        else
            sudo yum install -y epel-release
            sudo yum install -y stress
        fi
    fi

    # Verify stress installation
    if ! command -v stress &>/dev/null; then
        echo "❌ Failed to install stress utility"
        exit 1
    fi

    # Kill any existing stress processes
    echo "🧹 Cleaning up any existing stress processes..."
    sudo pkill stress || true
    
    # Start stress test in background
    echo "🚀 Running stress test..."
    stress --cpu 2 --timeout 300s &
    STRESS_PID=$!

    # Show current CPU usage
    echo "📊 Initial CPU usage:"
    top -b -n 1 | head -n 5

    # Monitor CPU usage for a short while
    for i in {1..5}; do
        sleep 30
        echo "📈 CPU usage at $(date):"
        top -b -n 1 | head -n 5
    done
EOF

# Step 3: Monitor Auto Scaling Group
echo -e "${YELLOW}📊 Monitoring Auto Scaling Group for new instances...${NC}"
echo "Initial ASG state:"
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-name "$ASG_NAME" \
    --region "$REGION" \
    --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState]' \
    --output table

# Monitor in a loop
echo -e "${YELLOW}Monitoring ASG changes... (Press Ctrl+C to stop)${NC}"
for i in {1..30}; do
    echo "Check $i of 30..."
    aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-name "$ASG_NAME" \
        --region "$REGION" \
        --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState]' \
        --output table
    
    # Monitor CPU Utilization
    echo "📈 CPU Utilization:"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/EC2 \
        --metric-name CPUUtilization \
        --dimensions Name=AutoScalingGroupName,Value="$ASG_NAME" \
        --statistics Average \
        --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 60 \
        --region "$REGION" \
        --query 'Datapoints[*].[Timestamp,Average]' \
        --output table

    sleep 10
done

# Show final ASG activities
echo -e "${YELLOW}📋 Recent ASG Activities:${NC}"
aws autoscaling describe-scaling-activities \
    --auto-scaling-group-name "$ASG_NAME" \
    --max-items 5 \
    --region "$REGION" \
    --query 'Activities[*].[StartTime,Description,Cause]' \
    --output table

echo -e "${GREEN}✅ Test completed!${NC}"

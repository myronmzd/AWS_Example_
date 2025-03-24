#!/bin/bash

# ===========================
# Auto Scaling Group Stress Test Script
# ===========================

# === Configuration ===
ASG_NAME="MyAutoScalingGroup"
REGION="ap-south-1"
KEY_PATH="MyKeyPair.pem"  # Ensure this is correctly set
STRESS_DURATION=300       # Duration in seconds

# === Color Codes for Output ===
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# === Error Handling ===
set -e
trap 'echo -e "${RED}❌ Error occurred on line $LINENO${NC}"' ERR

# === Check SSH Key File ===
if [ ! -f "${KEY_PATH/#\~/$HOME}" ]; then
    echo -e "${RED}❌ SSH key not found: $KEY_PATH${NC}"
    echo "Please update KEY_PATH in the script."
    exit 1
fi

# Ensure key has the correct permissions
chmod 400 "${KEY_PATH/#\~/$HOME}"

# ===========================
# STEP 1: Retrieve Instance IP
# ===========================
echo -e "${YELLOW}🔎 Fetching running instance details...${NC}"

INSTANCE_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:aws:autoscaling:groupName,Values=$ASG_NAME" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text \
    --region $REGION)

if [[ -z "$INSTANCE_IP" ]]; then
    echo -e "${RED}❌ No running instance found in ASG: $ASG_NAME!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Instance found at IP: $INSTANCE_IP${NC}"

# ===========================
# STEP 2: Connect & Run Stress Test
# ===========================
echo -e "${YELLOW}⚙️ Connecting via SSH and starting CPU stress test...${NC}"

ssh -i "${KEY_PATH/#\~/$HOME}" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    ec2-user@"$INSTANCE_IP" << 'EOF'
    
    echo "🔍 Checking if 'stress' utility is installed..."
    
    # Install stress if not present
    if ! command -v stress &>/dev/null; then
        echo "📦 Installing 'stress' utility..."
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

    # Verify installation
    if ! command -v stress &>/dev/null; then
        echo "❌ Failed to install 'stress' utility."
        exit 1
    fi

    echo "🧹 Stopping any existing stress processes..."
    sudo pkill stress || true

    echo "🚀 Starting CPU stress test for 300 seconds..."
    stress --cpu 2 --timeout 300s &

    echo "📊 CPU Usage before stress test:"
    top -b -n 1 | head -n 5

    # Monitor CPU usage
    for i in {1..5}; do
        sleep 30
        echo "📈 CPU Usage at $(date):"
        top -b -n 1 | head -n 5
    done
EOF

# ===========================
# STEP 3: Monitor Auto Scaling Group
# ===========================
echo -e "${YELLOW}📊 Monitoring Auto Scaling Group for changes...${NC}"
echo "🔹 Initial ASG state:"

aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-name "$ASG_NAME" \
    --region "$REGION" \
    --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState]' \
    --output table

echo -e "${YELLOW}⏳ Watching ASG changes for 5 minutes (Press Ctrl+C to stop)...${NC}"

for i in {1..30}; do
    echo "🔄 Check $i of 30..."
    
    # Fetch current ASG state
    aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-name "$ASG_NAME" \
        --region "$REGION" \
        --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState]' \
        --output table
    
    # Monitor CPU Utilization
    echo "📈 Current CPU Utilization:"
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

# ===========================
# STEP 4: Display ASG Activities
# ===========================
echo -e "${YELLOW}📋 Recent Auto Scaling Activities:${NC}"

aws autoscaling describe-scaling-activities \
    --auto-scaling-group-name "$ASG_NAME" \
    --max-items 5 \
    --region "$REGION" \
    --query 'Activities[*].[StartTime,Description,Cause]' \
    --output table

echo -e "${GREEN}✅ Stress test completed successfully!${NC}"

#!/bin/bash

# Set region
REGION="ap-south-1"
KEY_NAME="MyKeyPair"
ASG_NAME="MyAutoScalingGroup"

# 1. Check if key pair exists
echo "🔑 Checking key pair..."
if ! aws ec2 describe-key-pairs --region $REGION --key-names $KEY_NAME &>/dev/null; then
    echo "❌ Key pair $KEY_NAME not found in region $REGION"
    exit 1
fi

# 2. Get instance details
echo "🔎 Getting instance details..."
INSTANCE_INFO=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' \
    --output text)

if [ -z "$INSTANCE_INFO" ]; then
    echo "❌ No running instances found"
    exit 1
fi

INSTANCE_ID=$(echo $INSTANCE_INFO | awk '{print $1}')
INSTANCE_IP=$(echo $INSTANCE_INFO | awk '{print $2}')

# 2.2 Echo initial ASG state
echo "📊 Initial ASG State:"
aws autoscaling describe-auto-scaling-groups \
    --region $REGION \
    --auto-scaling-group-name $ASG_NAME

# 3. SSH and run stress test
echo "⚙️ Connecting to instance $INSTANCE_IP and running stress test..."
ssh -i ~/.ssh/$KEY_NAME.pem -o StrictHostKeyChecking=accept-new ec2-user@$INSTANCE_IP << 'EOF'
    # 3.1 & 3.2 Check and install stress
    if ! command -v stress &>/dev/null; then
        echo "Installing stress utility..."
        sudo yum install -y epel-release
        sudo yum install -y stress --enablerepo=epel
    fi

    # 3.3 Run stress test
    echo "Starting CPU stress test..."
    stress --cpu 2 --timeout 180s &
    STRESS_PID=$!

    # 3.4 Wait for stress test to complete
    sleep 180
    if ps -p $STRESS_PID > /dev/null; then
        kill $STRESS_PID
    fi
    echo "Stress test completed"
EOF

# 4. Check number of instances after stress
echo "⏳ Waiting for ASG to respond (60 seconds)..."
sleep 60
echo "📊 Current ASG State:"
aws autoscaling describe-auto-scaling-groups \
    --region $REGION \
    --auto-scaling-group-name $ASG_NAME

# 5. Echo ASG activities
echo "📋 Recent ASG Activities:"
aws autoscaling describe-scaling-activities \
    --region $REGION \
    --auto-scaling-group-name $ASG_NAME \
    --max-items 5

# 6. Get CloudWatch CPU metrics
echo "📈 CPU Utilization Metrics:"
aws cloudwatch get-metric-statistics \
    --region $REGION \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --start-time $(date -u -v-15M +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 60 \
    --statistics Average

# 7. Get CloudWatch ASG metrics
echo "📊 ASG Scaling Events:"
aws cloudwatch get-metric-statistics \
    --region $REGION \
    --namespace AWS/AutoScaling \
    --metric-name GroupTotalInstances \
    --dimensions Name=AutoScalingGroupName,Value=$ASG_NAME \
    --start-time $(date -u -v-15M +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 60 \
    --statistics Average
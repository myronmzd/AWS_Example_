#!/usr/bin/env bash

REGION="ap-south-1"
STACK_NAME="MyAutoScaling"


# Get latest Amazon Linux 2 AMI
Ec2_ami=$(aws ec2 describe-images \
    --region ap-south-1 \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
              "Name=architecture,Values=x86_64" \
              "Name=virtualization-type,Values=hvm" \
    --query "Images | sort_by(@, &CreationDate)[-1].{ImageId:ImageId}" \
    --output text)

# Check if AMI retrieval was successful
if [ -z "$Ec2_ami" ]; then
    echo "Error: No AMI found. Exiting."
    exit 1
fi

echo "Using AMI: $Ec2_ami"

MY_IP=$(curl -s https://checkip.amazonaws.com)/32
aws ssm put-parameter --name "MyPublicIP" --value "$MY_IP" --type String --overwrite --region "$REGION"


cat > template.yaml <<EOF
AWSTemplateFormatVersion: 2010-09-09
Description: A CloudFormation template to set up VPC, Subnet, NAT Gateway, and an EC2 instance.

Parameters:
  InstanceType:
    Description: Amazon EC2 instance type for the instances
    Type: String
    AllowedValues:
      - t2.micro
      - t3.nano
      - t3.small
    Default: t2.micro
  KeyPairName:
    Type: String
    Description: "Name of an existing EC2 Key Pair for SSH access"
    Default: MyKeyPair
  Ec2Ami:
    Type: String
    Default: $Ec2_ami
  AvailabilityZones:
    Type: List<String>
    Default: ap-south-1a,ap-south-1b
    AllowedValues:
      - ap-south-1a
      - ap-south-1b
  MyIP:
    Type: String
    Default: "${MY_IP}"
    Description: "Your public IP address"

Resources:

# Network resources ===========================================================================================

  MyVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: MyProductionVPC

  InternetGateway:
    Type: AWS::EC2::InternetGateway

  VPCGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref MyVPC
      InternetGatewayId: !Ref InternetGateway
  
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !Ref AvailabilityZones]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: PublicSubnet1

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [1, !Ref AvailabilityZones]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: PublicSubnet2

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref MyVPC

  PublicRoute:
    Type: AWS::EC2::Route
    DependsOn: VPCGatewayAttachment
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  SubnetRouteTableAssociation1:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet1

  SubnetRouteTableAssociation2:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet2

  # Create separate security group for ALB
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ALB
      VpcId: !Ref MyVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0  # Allow HTTP from anywhere
      SecurityGroupEgress:
        - IpProtocol: -1
          FromPort: -1
          ToPort: -1
          CidrIp: 0.0.0.0/0
    
  InstanceSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Enable SSH access via port 22
      VpcId: !Ref MyVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: !Ref MyIP
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          SourceSecurityGroupId: !Ref ALBSecurityGroup
        - IpProtocol: -1  # Allow all inbound traffic
          FromPort: -1    # No specific port (applies to all protocols)
          ToPort: -1      # No specific port (applies to all protocols)
          CidrIp: 0.0.0.0/0  # Allow from any IP address
      SecurityGroupEgress:
        - IpProtocol: -1
          FromPort: -1
          ToPort: -1
          CidrIp: 0.0.0.0/0
  
  MyLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    DependsOn: VPCGatewayAttachment
    Properties:
      Name: "MyALB"
      Scheme: internet-facing
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref ALBSecurityGroup

  # 🎯 Target Group for ALB
  MyTargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      VpcId: !Ref MyVPC
      Protocol: HTTP
      Port: 80
      TargetType: instance
      HealthCheckPath: "/"
  
  # Add ALB Listener
  ALBListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref MyTargetGroup
      LoadBalancerArn: !Ref MyLoadBalancer
      Port: 80
      Protocol: HTTP


# EC2 resources ===========================================================================================

  MyLaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties: 
      LaunchTemplateName: "MyLaunchTemplate"
      LaunchTemplateData:
        KeyName: !Ref KeyPairName
        SecurityGroupIds:
          - !Ref InstanceSecurityGroup
        ImageId: !Ref Ec2Ami
        IamInstanceProfile:
          Arn: !GetAtt SSMInstanceProfile.Arn
        InstanceType: !Ref InstanceType
        UserData:
          Fn::Base64: !Sub |
            #!/bin/bash
            sudo su - ec2-user
            sudo yum install -y httpd
            sudo systemctl start httpd
            sudo systemctl enable httpd
            echo "Hello from Amazon Linux!" | sudo tee /var/www/html/index.html
  

  SSMInstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Roles:
        - !Ref SSMRole

  SSMRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Service: ec2.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
          - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
          - arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess

  myASG:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AutoScalingGroupName: "MyAutoScalingGroup"
      LaunchTemplate:
        LaunchTemplateId: !Ref MyLaunchTemplate
        Version: !GetAtt MyLaunchTemplate.LatestVersionNumber
      MaxSize: 2
      MinSize: 1
      VPCZoneIdentifier: 
          - !Ref PublicSubnet1
          - !Ref PublicSubnet2
      # 🎯 Target Group for ASG
      TargetGroupARNs:
        - !Ref MyTargetGroup
      HealthCheckType: "ELB"
      HealthCheckGracePeriod: 300

  MyScalingPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AutoScalingGroupName: !Ref myASG
      PolicyType: TargetTrackingScaling
      TargetTrackingConfiguration:
        TargetValue: 50.0
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization
        DisableScaleIn: false
EOF


# Check if the stack exists
if aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK_NAME" >/dev/null 2>&1; then
    echo "🔄 Stack $STACK_NAME exists, updating it..."
    
    # Update the stack
    if ! aws cloudformation update-stack \
        --region "$REGION" \
        --stack-name "$STACK_NAME" \
        --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
        --template-body file://template.yaml; then
        echo "⚠️ Stack update failed. It may be because no changes were detected."
        exit 1
    else
        echo "✅ Stack update initiated successfully."
    fi
else
    echo "🚀 Stack $STACK_NAME does not exist, creating it..."
    
    # Create the stack
    if ! aws cloudformation create-stack \
        --region "$REGION" \
        --stack-name "$STACK_NAME" \
        --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
        --template-body file://template.yaml; then
        echo "❌ Stack creation failed."
        exit 1
    else
        echo "✅ Stack creation initiated successfully."
    fi
fi

# Color definitions
GRAY='\033[1;30m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo "Monitoring CloudFormation stack status: $STACK_NAME"

while true; do
  echo -e "\n=============================="
  echo "Checking resource status at $(date)"
  echo "=============================="

  while IFS=$'\t' read -r resource_id resource_type resource_status; do
    if [[ "$resource_status" == "⏳ CREATE_IN_PROGRESS" ]]; then
      echo -e "${GRAY}$resource_id ($resource_type) -- $resource_status${RESET}"
    elif [[ "$resource_status" == "✅ CREATE_COMPLETE" ]]; then
      echo -e "${GREEN}$resource_id ($resource_type) -- $resource_status${RESET}"
    else
      echo "$resource_id ($resource_type) -- $resource_status"
    fi
  done < <(aws cloudformation describe-stack-resources \
          --stack-name "$STACK_NAME" \
          --query "StackResources[*].[LogicalResourceId, ResourceType, ResourceStatus]" \
          --output text)

  FINAL_STATUS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].StackStatus" --output text)

  if [[ "$FINAL_STATUS" == "✅ CREATE_COMPLETE" ]]; then
    echo -e "\n=============================="
    echo -e "${GREEN}Final Stack Status: $FINAL_STATUS"
    echo "All resources are started.${RESET}"
    echo "=============================="
    break
  elif [[ "$FINAL_STATUS" == *"FAILED"* || "$FINAL_STATUS" == *"ROLLBACK"* ]]; then
    echo -e "\n=============================="
    echo "Final Stack Status: $FINAL_STATUS"
    echo "Stack creation failed or rolled back."
    echo "=============================="
    break
  fi
  sleep 8
done
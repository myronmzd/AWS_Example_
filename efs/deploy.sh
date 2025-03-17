#!/usr/bin/env bash

# Get latest Amazon Linux 2 AMI
Ec2_aim=$(aws ec2 describe-images \
    --region ap-south-1 \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
              "Name=architecture,Values=x86_64" \
              "Name=virtualization-type,Values=hvm" \
    --query "Images | sort_by(@, &CreationDate)[-1].{ImageId:ImageId}" \
    --output text)
echo "$Ec2_aim"

# Check if AMI retrieval was successful
if [ -z "$Ec2_aim" ]; then
    echo "Error: No AMI found. Exiting."
    exit 1
fi

echo "Using AMI: $Ec2_aim"

MY_IP=$(curl -s https://checkip.amazonaws.com)/32
aws ssm put-parameter --name "MyPublicIP" --value "$MY_IP" --type String --overwrite


cat > template.yaml <<EOF
AWSTemplateFormatVersion: 2010-09-09
Description: A CloudFormation template to set up VPC, Subnet, NAT Gateway, and an EC2 instance.

Parameters:
  InstanceType:
    Type: String
    Default: t2.micro
  Ec2Ami:
    Type: String
    Default: $Ec2_aim
  AvailabilityZone:
    Type: String
    Default: ap-south-1a
    AllowedValues: [ap-south-1a, ap-south-1b]
  MyIP:
    Type: String
    Default: ${MY_IP}
    Description: "Your public IP address"

Resources:
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
  
  PublicSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Ref AvailabilityZone
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: PublicSubnet

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref MyVPC

  PublicRoute:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  SubnetRouteTableAssociationPublic:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet
    
  InstanceSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow SSH access only
      VpcId: !Ref MyVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 2049
          ToPort: 2049
          CidrIp: 10.0.0.0/16  # VPC CIDR
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: !Ref MyIP
        - IpProtocol: -1  # Allow all inbound traffic
          FromPort: -1    # No specific port (applies to all protocols)
          ToPort: -1      # No specific port (applies to all protocols)
          CidrIp: 0.0.0.0/0  # Allow from any IP address
      SecurityGroupEgress:
        - IpProtocol: tcp
          FromPort: 2049
          ToPort: 2049
          CidrIp: 10.0.0.0/16
        - IpProtocol: -1
          FromPort: -1
          ToPort: -1
          CidrIp: 0.0.0.0/0

  MyInstance:
    Type: AWS::EC2::Instance
    DependsOn: MountTarget 
    Properties:
      ImageId: !Ref Ec2Ami
      InstanceType: !Ref InstanceType
      SubnetId: !Ref PublicSubnet
      IamInstanceProfile: !Ref SSMInstanceProfile
      SecurityGroupIds:
        - !Ref InstanceSecurityGroup
      KeyName: MyKeyPair
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          sudo su - ec2-user
          yum update -y
          yum install -y amazon-ssm-agent
          systemctl enable amazon-ssm-agent
          systemctl start amazon-ssm-agent
          systemctl enable sshd
          systemctl start sshd
          echo "<h1>Welcome to Myron Server on EC2</h1>" > /var/www/html/index.html
          # Install EFS utils
          sudo yum install -y amazon-efs-utils
          sudo mkdir -p /mnt/efs
          if ! mount -t efs ${FileSystemResource}:/ /mnt/efs; then
            echo "Failed to mount EFS"
            exit 1
          fi

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

  FileSystemResource:
    Type: AWS::EFS::FileSystem
    Properties:
      BackupPolicy:
        Status: DISABLED
      PerformanceMode: generalPurpose
      Encrypted: true
      FileSystemTags:
        - Key: Name
          Value: TestFileSystem
        - Key: Environment
          Value: Production
        - Key: Purpose
          Value: Testing

  MountTarget: 
      Type: AWS::EFS::MountTarget
      DependsOn: VPCGatewayAttachment
      Properties: 
          FileSystemId: !Ref FileSystemResource
          SubnetId: !Ref PublicSubnet
          SecurityGroups: 
            - !Ref InstanceSecurityGroup 
EOF

# Deploy CloudFormation stack
if ! aws cloudformation create-stack \
  --region ap-south-1 \
  --stack-name MyEFSstack \
  --output text \
  --capabilities CAPABILITY_IAM \
  --template-body file://template.yaml; then
    echo "Stack creation failed"
    exit 1
fi

STACK_NAME="MyEFSstack"

# Color definitions
GRAY='\033[1;30m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo "Monitoring CloudFormation stack status: $STACK_NAME"

while true; do
  echo -e "\n=============================="
  echo "Checking resource status at $(date)"
  echo "=============================="

  aws cloudformation describe-stack-resources \
    --stack-name "$STACK_NAME" \
    --query "StackResources[*].[LogicalResourceId, ResourceType, ResourceStatus]" \
    --output text | while read -r resource_id resource_type resource_status; do
    
    if [[ "$resource_status" == "CREATE_IN_PROGRESS" ]]; then
      echo -e "${GRAY}$resource_id ($resource_type) -- $resource_status${RESET}"
    elif [[ "$resource_status" == "CREATE_COMPLETE" ]]; then
      echo -e "${GREEN}$resource_id ($resource_type) -- $resource_status${RESET}"
    else
      echo "$resource_id ($resource_type) -- $resource_status"
    fi
  done

  FINAL_STATUS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].StackStatus" --output text)

  if [[ "$FINAL_STATUS" == "CREATE_COMPLETE" ]]; then
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
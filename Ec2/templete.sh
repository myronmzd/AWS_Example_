#!/usr/bin/env bash

Ec2_aim=$(aws ec2 describe-images \
    --region ap-south-1 \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
              "Name=architecture,Values=x86_64" \
              "Name=virtualization-type,Values=hvm" \
    --query "Images | sort_by(@, &CreationDate)[-1].{ImageId:ImageId}" \
    --output text)
echo "$Ec2_aim"

aws cloudformation create-stack \
  --region ap-south-1 \
  --stack-name MyVPCStack \
  --output text \
  --template-body "$(cat <<EOF
AWSTemplateFormatVersion: 2010-09-09
Description: A CloudFormation template to set up VPC, Subnet, NAT Gateway, and an EC2 instance.

Parameters:
  InstanceType:
    Type: String
    Default: t2.micro
  Ec2Ami:
    Type: String
    Default: ami-0b8e60a84f14ce5a3
  AvailabilityZone:
    Type: String
    Default: ap-south-1a
    AllowedValues: [ap-south-1a, ap-south-1b]

Resources:
  MyVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 192.168.0.0/16
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
      CidrBlock: 192.168.1.0/24
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
          FromPort: 22
          ToPort: 22
          CidrIp: 192.168.1.3/32
        - IpProtocol: -1  # Allow all inbound traffic
          FromPort: -1    # No specific port (applies to all protocols)
          ToPort: -1      # No specific port (applies to all protocols)
          CidrIp: 0.0.0.0/0  # Allow from any IP address
      SecurityGroupEgress:
        - IpProtocol: -1
          FromPort: -1
          ToPort: -1
          CidrIp: 0.0.0.0/0



  MyInstance:
    Type: AWS::EC2::Instance
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
          yum update -y
          yum install -y amazon-ssm-agent
          systemctl enable amazon-ssm-agent
          systemctl start amazon-ssm-agent
          systemctl enable sshd
          systemctl start sshd
          echo "<h1>Welcome to Myron Server on EC2</h1>" > /var/www/html/index.html

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

)"

echo "Monitoring CloudFormation events for stack: MyVPCStack"

# Store the last event timestamp to avoid duplicate events
LAST_EVENT_ID=""

while true; do
  # Fetch stack events sorted by time descending
  aws cloudformation describe-stack-events \
    --stack-name MyVPCStack \
    --query "StackEvents[*].[EventId, LogicalResourceId, ResourceStatus, Timestamp]" \
    --output table | tail -n +3 | head -n -1 > current_events.txt

  # Print events if any new ones appear
  NEW_EVENT=$(head -1 current_events.txt | awk '{print $1}')
  
  if [[ "$NEW_EVENT" != "$LAST_EVENT_ID" ]]; then
    cat current_events.txt
    LAST_EVENT_ID="$NEW_EVENT"
  fi

  # Stop monitoring if the stack reaches a stable state
  STATUS=$(aws cloudformation describe-stacks \
    --stack-name MyVPCStack \
    --query "Stacks[0].StackStatus" --output text)

  if [[ "$STATUS" == "CREATE_COMPLETE" || "$STATUS" == "CREATE_FAILED" || "$STATUS" == *"ROLLBACK"* ]]; then
    echo "Final Stack Status: $STATUS"
    break
  fi

  sleep 10
done

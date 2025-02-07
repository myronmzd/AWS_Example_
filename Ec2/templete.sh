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
Description: A CloudFormation template to run an EC2 instance 

Resources:
  NewKeyPair:
    Type: 'AWS::EC2::KeyPair'
    Properties: 
      KeyName: key-Ec2-test-SSH
      
  myInstance:
    Type: 'AWS::EC2::Instance'
    Properties: 
      ImageId: $Ec2_aim
      SubnetId: !Ref mySubnet
      SecurityGroupIds:
        - !Ref InstanceSecurityGroup
      KeyName: key-Ec2-test-SSH
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          yum update -y
          service httpd start
          chkconfig httpd on

  mySubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref myVPC
      CidrBlock: 192.168.1.0/28
      AvailabilityZone: ap-south-1a
      Tags:
        - Key: stack
          Value: production

  myVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 192.168.1.0/24
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: MyProductionVPC

  InstanceSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow SSH access only
      VpcId: !Ref myVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 192.168.1.3/32
      SecurityGroupEgress: []


EOF
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

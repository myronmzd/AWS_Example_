#!/usr/bin/env bash

REGION="ap-south-1"
STACK_NAME="MyRDSStack"
KEY_NAME="MyKeybas"  # Replace with your key pair name

export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT=text  

echo "🔍 Discovering latest Amazon Linux 2 AMI in $REGION ..."
Ec2_aim=$(aws ec2 describe-images \
    --region ap-south-1 \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
              "Name=architecture,Values=x86_64" \
              "Name=virtualization-type,Values=hvm" \
    --query "Images | sort_by(@, &CreationDate)[-1].{ImageId:ImageId}" \
    --output text)

if [ -z "$Ec2_aim" ]; then
    echo "Error: No AMI found. Exiting."
    exit 1
fi
echo "✅ AMI found: $Ec2_aim"

MY_IP=$(curl -s https://checkip.amazonaws.com)/32
aws ssm put-parameter --name "MyPublicIP" --value "$MY_IP" --type String --overwrite


cat > template.yaml <<EOF
AWSTemplateFormatVersion: 2010-09-09
Description: Set up VPC, public subnet with Bastion, private subnets with PostgreSQL RDS.

Parameters:
  DBName:
    Type: String
    Default: mydb
  DBUser:
    Type: String
    Default: bob
  DBPassword:
    Type: String
    NoEcho: true
    Default: ChangeMe123!
  DBAllocatedStorage:
    Type: Number
    Default: 20
  DBInstanceClass:
    Type: String
    Default: db.t3.micro
  AllowedIP:
    Type: String
    Default: "${MY_IP}"
    Description: CIDR allowed SSH / DB access
  Ec2Ami:
    Type: String
    Default: "${Ec2_aim}"
  KeyName:
    Type: AWS::EC2::KeyPair::KeyName
    Default: "${KEY_NAME}"
    Description: Existing key pair for Bastion SSH

Resources:
  MyVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags: [{ Key: Name, Value: MyVPC }]

  MyIGW:
    Type: AWS::EC2::InternetGateway
  VPCGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref MyVPC
      InternetGatewayId: !Ref MyIGW

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref MyVPC
  RouteToIGW:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref MyIGW

  PublicSubnetA:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC
      CidrBlock: 10.0.1.0/24
      MapPublicIpOnLaunch: true
      AvailabilityZone: !Select [0, !GetAZs '']
  
  PublicSubnetB:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC
      CidrBlock: 10.0.2.0/24
      MapPublicIpOnLaunch: true
      AvailabilityZone: !Select [1, !GetAZs '']
    
  SubnetARouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnetA
      RouteTableId: !Ref PublicRouteTable

  SubnetBRouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnetB
      RouteTableId: !Ref PublicRouteTable

  BastionSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow SSH from your IP
      VpcId: !Ref MyVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: !Ref AllowedIP

  BastionHost:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t3.micro
      ImageId: !Ref Ec2Ami
      SubnetId: !Ref PublicSubnetA
      SecurityGroupIds: [!Ref BastionSecurityGroup]
      KeyName: !Ref KeyName
      Tags: [{ Key: Name, Value: BastionHost }]

  MyDBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow Postgres from Bastion host
      VpcId: !Ref MyVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          SourceSecurityGroupId: !Ref BastionSecurityGroup

  MyDBSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupDescription: Subnets for RDS
      SubnetIds:
        - !Ref PublicSubnetA
        - !Ref PublicSubnetB

  MyDB:
    Type: AWS::RDS::DBInstance
    Properties:
      DBName: !Ref DBName
      AllocatedStorage: !Ref DBAllocatedStorage
      StorageType: gp3
      DBInstanceClass: !Ref DBInstanceClass
      Engine: postgres
      MasterUsername: !Ref DBUser
      MasterUserPassword: !Ref DBPassword
      VPCSecurityGroups: [!GetAtt MyDBSecurityGroup.GroupId]
      DBSubnetGroupName: !Ref MyDBSubnetGroup
      PubliclyAccessible: false
      StorageEncrypted: true
      BackupRetentionPeriod: 7
      DeletionProtection: true

Outputs:
  DBEndpoint:
    Description: Postgres endpoint DNS
    Value: !GetAtt MyDB.Endpoint.Address

EOF

# Deploy CloudFormation stack
if ! aws cloudformation create-stack \
  --region "$REGION" \
  --stack-name "$STACK_NAME" \
  --output text \
  --capabilities CAPABILITY_IAM \
  --template-body file://template.yaml \
  --parameters ParameterKey=KeyName,ParameterValue="$KEY_NAME" \
    ParameterKey=AllowedIP,ParameterValue="$MY_IP" \
    ParameterKey=Ec2Ami,ParameterValue="$Ec2_aim"; then
    echo "Stack creation failed"
    exit 1
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
    if [[ "$resource_status" == " CREATE_IN_PROGRESS" ]]; then
      echo -e "${GRAY}$resource_id ($resource_type) -- $resource_status${RESET}"
    elif [[ "$resource_status" == "CREATE_COMPLETE" ]]; then
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
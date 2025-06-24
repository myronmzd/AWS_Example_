#!/usr/bin/env bash
# This script deploys a CloudFormation stack to set up a VPC, Subnet and an RDS instance with security groups.

MY_IP=$(curl -s https://checkip.amazonaws.com)/32
aws ssm put-parameter --name "MyPublicIP" --value "$MY_IP" --type String --overwrite

MY_IP=$(curl -s https://checkip.amazonaws.com)/32
aws ssm put-parameter --name "MyPublicIP" --value "$MY_IP" --type String --overwrite --region "$REGION"

if [ -z "$MY_IP" ]; then
    echo "Error: Could not retrieve public IP address"
    exit 1
else
    echo "✅ Using your IP address is $MY_IP"
fi



cat > template.yaml <<EOF
AWSTemplateFormatVersion: 2010-09-09
Description: A CloudFormation template to set up VPC, Subnet, NAT Gateway, and an EC2 instance.

Parameters:
  DBName:
    Type: String
    Default: mydb
  DBUser:
    Type: String
    Default: admin
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
    Default: "$MY_IP"
    Description: The IP address allowed to access the database.

Resources:
  MyVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: MyVPC
 
  MySubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC
      CidrBlock: 10.0.1.0/24
      MapPublicIpOnLaunch: true
      AvailabilityZone: !Select [0, !GetAZs '']

  MyDBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Enable MySQL access from AllowedIP
      VpcId: !Ref MyVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 3306
          ToPort: 3306
          CidrIp: !Ref AllowedIP

  MyKMSKey:
    Type: AWS::KMS::Key
    Properties:
      Description: KMS key for RDS secrets
      EnableKeyRotation: true
      KeyPolicy:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              AWS: !Sub arn:aws:iam::${AWS::AccountId}:root
            Action: "kms:*"
            Resource: "*"

  MyDB:
    Type: AWS::RDS::DBInstance
    Properties:
      DBName: !Ref DBName
      AllocatedStorage: !Ref DBAllocatedStorage
      DBInstanceClass: !Ref DBInstanceClass
      Engine: mysql
      MasterUsername: !Ref DBUser
      MasterUserPassword: !Ref DBPassword
      VPCSecurityGroups:
        - !GetAtt MyDBSecurityGroup.GroupId
      DBSubnetGroupName: !Ref MyDBSubnetGroup
      PubliclyAccessible: true
      DeletionProtection: false
  
  MyDBSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupDescription: Subnet group for RDS instance
      SubnetIds:
        - !Ref MySubnet
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
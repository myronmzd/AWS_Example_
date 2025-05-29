cat > template.yaml <<EOF
AWSTemplateFormatVersion: 2010-09-09
Description: A CloudFormation template to run an EC2 instance to connect to ElastiCache Redis Cluster 

Parameters:
  InstanceType:
    Type: String
    Default: t3.micro
  SubnetID: 
    Type: String
    Default:  subnet-016504b33fee4c0bc
  ImageID:
    Type: String  
    Default: ami-0e35ddab05955cf57
  myVPC:
    Type: String
    Default: vpc-043aa264bbdd65d4d
  mysecurityGroup:
    Type: String
    Default: sg-06d0c094aa641a478

Resources:
  MyEC2Instance: 
    Type: AWS::EC2::Instance
    Properties: 
      InstanceType: !Ref InstanceType
      ImageId: !Ref ImageID
      SubnetId: !Ref SubnetID
      IamInstanceProfile: !Ref EC2InstanceProfile
      KeyName: mykey
      SecurityGroupIds:
       - !Ref mysecurityGroup
      UserData: !Base64 |
        #!/bin/bash
        sudo su -
        # Install necessary packages
        sudo apt update -y             
        sudo apt upgrade -y  
        sudo apt install -y python3-pip
        sudo apt install -y python3-dev

        # Install Python packages
        sudo apt install -y redis-tools

  # Create the IAM Role for the EC2 Instance
  EC2Role:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Action: "sts:AssumeRole"
            Principal:
              Service: ec2.amazonaws.com
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
  EC2InstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Roles:
        - !Ref EC2Role
EOF
# Create the CloudFormation stack
if ! aws cloudformation create-stack \
  --region ap-south-1 \
  --stack-name MyElasticEc2Stack \
  --output text \
  --capabilities CAPABILITY_IAM \
  --template-body file://template.yaml;then
    echo "Stack creation failed"
    exit 1
fi


STACK_NAME="MyElasticEc2Stack"

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

#!/bin/bash

# Variables
STACK_NAME="DynamoDBStack"
TEMPLATE_FILE="template.yaml"

# Validate the CloudFormation template
echo "Validating CloudFormation template..."
aws cloudformation validate-template --template-body file://$TEMPLATE_FILE

if [ $? -ne 0 ]; then
  echo "Template validation failed. Exiting."
  exit 1
fi

# Deploy the CloudFormation stack
echo "Deploying CloudFormation stack..."
aws cloudformation deploy \
  --stack-name $STACK_NAME \
  --template-file $TEMPLATE_FILE \
  --capabilities CAPABILITY_NAMED_IAM 

# Check stack status
if [ $? -eq 0 ]; then
  echo "CloudFormation stack deployed successfully!"
else
  echo "Failed to deploy CloudFormation stack."
  exit 1
fi

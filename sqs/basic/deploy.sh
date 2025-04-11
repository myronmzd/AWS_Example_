#!/usr/bin/env bash

echo "== Deploying S3 CloudFormation bucket =="

STACK_NAME="CFN-QUEUE-simple"

aws cloudformation deploy \
  --template-file template.yaml \
  --region ap-south-1 \
  --stack-name "$STACK_NAME"
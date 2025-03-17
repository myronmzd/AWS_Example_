#!/usr/bin/env bash

echo  "==deploy S3 cloudformation a bucket"

STACK_NAME="CFN-S3-simple"

aws cloudformation deploy \
--template-file /workspace/AWS_Example_/iac/Template.yaml \
--region ap-south-1 \
--stack-name $STACK_NAME \
--on-failure DO_NOTHING

